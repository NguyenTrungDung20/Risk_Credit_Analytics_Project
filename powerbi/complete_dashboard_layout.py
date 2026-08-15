from __future__ import annotations

import copy
import json
import uuid
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PBIX_IN = ROOT / "powerbi" / "Risk_Credit_Analytics_Project.pbix"
PBIX_OUT = ROOT / "powerbi" / "Risk_Credit_Analytics_Project_completed.pbix"

SUM = 0
AVERAGE = 1
COUNT = 2
DISTINCT_COUNT = 5

ALIASES = {
    "Dim_Geography": "d",
    "Fact_loans": "f",
    "Fact_SegmentMembership": "s",
    "_Measures": "_",
}

TYPE_CATEGORY = 2048
TYPE_PERCENT = 1
TYPE_NUMBER = 3

UNDERLYING_TEXT = 1
UNDERLYING_PERCENT = 259
UNDERLYING_NUMBER = 260

FMT_PERCENT = "0.00%;-0.00%;0.00%"
FMT_NUMBER = "#,0"
FMT_DECIMAL = "0.00"
FMT_MONEY = "$#,0;($#,0);$#,0"


def new_name() -> str:
    return uuid.uuid4().hex[:20]


def dumps(obj: object) -> str:
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":"))


def decode_layout(raw: bytes) -> dict:
    text = raw.decode("utf-16le")
    return json.loads(text.lstrip("\ufeff"))


def encode_layout(layout: dict) -> bytes:
    return dumps(layout).encode("utf-16le")


def source(table: str) -> dict:
    return {"Name": ALIASES[table], "Entity": table, "Type": 0}


def from_clause(tables: list[str]) -> dict | list[dict]:
    items = [source(table) for table in tables]
    return items[0] if len(items) == 1 else items


def col_ref(table: str, column: str) -> str:
    return f"{table}.{column}"


def sum_ref(table: str, column: str) -> str:
    return f"Sum({table}.{column})"


def avg_ref(table: str, column: str) -> str:
    return f"Average({table}.{column})"


def count_ref(table: str, column: str) -> str:
    return f"Count({table}.{column})"


def distinct_count_ref(table: str, column: str) -> str:
    return f"DistinctCount({table}.{column})"


def column_select(table: str, column: str, label: str) -> dict:
    alias = ALIASES[table]
    return {
        "Column": {
            "Expression": {"SourceRef": {"Source": alias}},
            "Property": column,
        },
        "Name": col_ref(table, column),
        "NativeReferenceName": label,
    }


def measure_select(measure: str, label: str | None = None) -> dict:
    return {
        "Measure": {
            "Expression": {"SourceRef": {"Source": "_"}},
            "Property": measure,
        },
        "Name": f"_Measures.{measure}",
        "NativeReferenceName": label or measure,
    }


def aggregate_select(
    table: str,
    column: str,
    function: int,
    query_name: str,
    label: str,
) -> dict:
    alias = ALIASES[table]
    return {
        "Aggregation": {
            "Expression": {
                "Column": {
                    "Expression": {"SourceRef": {"Source": alias}},
                    "Property": column,
                }
            },
            "Function": function,
        },
        "Name": query_name,
        "NativeReferenceName": label,
    }


def transform_expr_column(table: str, column: str) -> dict:
    return {
        "Column": {
            "Expression": {"SourceRef": {"Entity": table}},
            "Property": column,
        }
    }


def transform_expr_measure(measure: str) -> dict:
    return {
        "Measure": {
            "Expression": {"SourceRef": {"Entity": "_Measures"}},
            "Property": measure,
        }
    }


def transform_expr_aggregate(table: str, column: str, function: int) -> dict:
    return {
        "Aggregation": {
            "Expression": transform_expr_column(table, column),
            "Function": function,
        }
    }


def set_position(vc: dict, cfg: dict, x: float, y: float, w: float, h: float, z: int, tab: int) -> None:
    vc["x"] = x
    vc["y"] = y
    vc["z"] = z
    vc["width"] = w
    vc["height"] = h
    vc["tabOrder"] = tab
    position = cfg["layouts"][0]["position"]
    position.update({"x": x, "y": y, "z": z, "width": w, "height": h, "tabOrder": tab})


def parsed(vc: dict) -> tuple[dict, dict | None, dict | None]:
    cfg = json.loads(vc["config"])
    query = json.loads(vc["query"]) if "query" in vc else None
    transforms = json.loads(vc["dataTransforms"]) if "dataTransforms" in vc else None
    return cfg, query, transforms


def finish(vc: dict, cfg: dict, query: dict | None, transforms: dict | None) -> dict:
    cfg["name"] = new_name()
    vc["config"] = dumps(cfg)
    if query is not None:
        vc["query"] = dumps(query)
    if transforms is not None:
        vc["dataTransforms"] = dumps(transforms)
    return vc


def set_query(query: dict, tables: list[str], selects: list[dict]) -> None:
    q = query["Commands"][0]["SemanticQueryDataShapeCommand"]["Query"]
    q["From"] = from_clause(tables)
    q["Select"] = selects[0] if len(selects) == 1 else selects


def set_prototype(cfg: dict, tables: list[str], selects: list[dict]) -> None:
    proto = cfg["singleVisual"].setdefault("prototypeQuery", {})
    proto["From"] = from_clause(tables)
    proto["Select"] = selects[0] if len(selects) == 1 else selects


def meta_for_field(field: dict) -> dict:
    role = field["role"]
    name = field["query_name"]
    label = field["label"]
    expr = field["expr"]
    is_percent = field.get("format") == FMT_PERCENT
    if field["kind"] == "column":
        typ = TYPE_CATEGORY
        out = {"Restatement": label, "Name": name, "Type": typ}
        if field.get("data_category"):
            out["DataCategory"] = field["data_category"]
        return out
    typ = TYPE_PERCENT if is_percent else TYPE_NUMBER
    out = {"Restatement": label, "Name": name, "Type": typ}
    if field.get("format"):
        out["Format"] = field["format"]
    return out


def transform_select_for_field(field: dict) -> dict:
    is_percent = field.get("format") == FMT_PERCENT
    if field["kind"] == "column":
        typ = {"category": field.get("category"), "underlyingType": UNDERLYING_TEXT}
    else:
        typ = {"category": None, "underlyingType": UNDERLYING_PERCENT if is_percent else UNDERLYING_NUMBER}
    return {
        "displayName": field["label"],
        "queryName": field["query_name"],
        "roles": {field["role"]: True},
        "type": typ,
        "expr": field["expr"],
    }


def set_transforms(
    transforms: dict,
    fields: list[dict],
    active_roles: set[str],
    sort_index: int | None = None,
    sort_order: int = 0,
) -> None:
    transforms["projectionOrdering"] = {}
    transforms["projectionActiveItems"] = {}
    for idx, field in enumerate(fields):
        transforms["projectionOrdering"].setdefault(field["role"], []).append(idx)
        if field["role"] in active_roles:
            transforms["projectionActiveItems"].setdefault(field["role"], []).append(
                {"queryRef": field["query_name"], "suppressConcat": False}
            )
    transforms["queryMetadata"] = {
        "Select": [meta_for_field(field) for field in fields],
        "Filters": [{"type": 0 if field["kind"] == "column" else 2, "expression": field["expr"]} for field in fields],
    }
    transforms["visualElements"] = [
        {
            "DataRoles": [
                {"Name": field["role"], "Projection": idx, "isActive": field["role"] in active_roles}
                for idx, field in enumerate(fields)
            ]
        }
    ]
    selects = [transform_select_for_field(field) for field in fields]
    if sort_index is not None and 0 <= sort_index < len(selects):
        selects[sort_index]["sort"] = 2
        selects[sort_index]["sortOrder"] = sort_order
    transforms["selects"] = selects


def column_field(role: str, table: str, column: str, label: str, category: str | None = None) -> dict:
    return {
        "role": role,
        "kind": "column",
        "table": table,
        "column": column,
        "label": label,
        "query_name": col_ref(table, column),
        "select": column_select(table, column, label),
        "expr": transform_expr_column(table, column),
        "category": category,
    }


def measure_field(role: str, measure: str, label: str | None = None, fmt: str | None = None) -> dict:
    label = label or measure
    return {
        "role": role,
        "kind": "measure",
        "label": label,
        "query_name": f"_Measures.{measure}",
        "select": measure_select(measure, label),
        "expr": transform_expr_measure(measure),
        "format": fmt,
    }


def agg_field(
    role: str,
    table: str,
    column: str,
    function: int,
    query_name: str,
    label: str,
    fmt: str | None = None,
) -> dict:
    return {
        "role": role,
        "kind": "aggregate",
        "table": table,
        "column": column,
        "label": label,
        "query_name": query_name,
        "select": aggregate_select(table, column, function, query_name, label),
        "expr": transform_expr_aggregate(table, column, function),
        "format": fmt,
    }


def visual_base(template: dict, x: float, y: float, w: float, h: float, z: int, tab: int) -> tuple[dict, dict, dict, dict]:
    vc = copy.deepcopy(template)
    cfg, query, transforms = parsed(vc)
    set_position(vc, cfg, x, y, w, h, z, tab)
    return vc, cfg, query, transforms


def make_text(
    template: dict,
    text: str,
    x: float,
    y: float,
    w: float,
    h: float,
    z: int,
    tab: int,
    font_size: str = "20pt",
    bold: bool = True,
) -> dict:
    vc = copy.deepcopy(template)
    cfg, _, _ = parsed(vc)
    set_position(vc, cfg, x, y, w, h, z, tab)
    runs = []
    for line in text.split("\n"):
        style = {"fontSize": font_size}
        if bold:
            style["fontWeight"] = "bold"
        runs.append({"textRuns": [{"value": line, "textStyle": style}]})
    cfg["singleVisual"]["objects"]["general"][0]["properties"]["paragraphs"] = runs
    vc.pop("query", None)
    vc.pop("dataTransforms", None)
    return finish(vc, cfg, None, None)


def make_slicer(
    template: dict,
    table: str,
    column: str,
    label: str,
    x: float,
    y: float,
    w: float,
    h: float,
    z: int,
    tab: int,
    category: str | None = None,
) -> dict:
    vc, cfg, query, transforms = visual_base(template, x, y, w, h, z, tab)
    field = column_field("Values", table, column, label, category)
    cfg["singleVisual"]["projections"] = {"Values": [{"queryRef": field["query_name"], "active": True}]}
    set_prototype(cfg, [table], [field["select"]])
    set_query(query, [table], [field["select"]])
    set_transforms(transforms, [field], {"Values"})
    return finish(vc, cfg, query, transforms)


def make_card_measure(
    template: dict,
    measure: str,
    label: str,
    fmt: str,
    x: float,
    y: float,
    w: float,
    h: float,
    z: int,
    tab: int,
) -> dict:
    vc, cfg, query, transforms = visual_base(template, x, y, w, h, z, tab)
    field = measure_field("Data", measure, label, fmt)
    cfg["singleVisual"]["projections"] = {"Data": [{"queryRef": field["query_name"]}]}
    set_prototype(cfg, ["_Measures"], [field["select"]])
    set_query(query, ["_Measures"], [field["select"]])
    set_transforms(transforms, [field], set())
    return finish(vc, cfg, query, transforms)


def make_card_agg(
    template: dict,
    table: str,
    column: str,
    function: int,
    query_name: str,
    label: str,
    fmt: str,
    x: float,
    y: float,
    w: float,
    h: float,
    z: int,
    tab: int,
) -> dict:
    vc, cfg, query, transforms = visual_base(template, x, y, w, h, z, tab)
    field = agg_field("Data", table, column, function, query_name, label, fmt)
    cfg["singleVisual"]["projections"] = {"Data": [{"queryRef": field["query_name"]}]}
    set_prototype(cfg, [table], [field["select"]])
    set_query(query, [table], [field["select"]])
    set_transforms(transforms, [field], set())
    return finish(vc, cfg, query, transforms)


def make_category_measure_chart(
    template: dict,
    visual_type: str,
    category_table: str,
    category_col: str,
    category_label: str,
    measure: str,
    measure_label: str,
    fmt: str,
    x: float,
    y: float,
    w: float,
    h: float,
    z: int,
    tab: int,
) -> dict:
    vc, cfg, query, transforms = visual_base(template, x, y, w, h, z, tab)
    cfg["singleVisual"]["visualType"] = visual_type
    cfg["singleVisual"].setdefault("objects", {}).pop("dataPoint", None)
    cat = column_field("Category", category_table, category_col, category_label)
    val = measure_field("Y", measure, measure_label, fmt)
    fields = [cat, val]
    cfg["singleVisual"]["projections"] = {
        "Category": [{"queryRef": cat["query_name"], "active": True}],
        "Y": [{"queryRef": val["query_name"]}],
    }
    tables = [category_table, "_Measures"]
    set_prototype(cfg, tables, [field["select"] for field in fields])
    set_query(query, tables, [field["select"] for field in fields])
    set_transforms(transforms, fields, {"Category"})
    return finish(vc, cfg, query, transforms)


def make_category_agg_chart(
    template: dict,
    visual_type: str,
    category_table: str,
    category_col: str,
    category_label: str,
    value_table: str,
    value_col: str,
    function: int,
    value_query_name: str,
    value_label: str,
    fmt: str,
    x: float,
    y: float,
    w: float,
    h: float,
    z: int,
    tab: int,
) -> dict:
    vc, cfg, query, transforms = visual_base(template, x, y, w, h, z, tab)
    cfg["singleVisual"]["visualType"] = visual_type
    cfg["singleVisual"].setdefault("objects", {}).pop("dataPoint", None)
    cat = column_field("Category", category_table, category_col, category_label)
    val = agg_field("Y", value_table, value_col, function, value_query_name, value_label, fmt)
    fields = [cat, val]
    cfg["singleVisual"]["projections"] = {
        "Category": [{"queryRef": cat["query_name"], "active": True}],
        "Y": [{"queryRef": val["query_name"]}],
    }
    tables = list(dict.fromkeys([category_table, value_table]))
    set_prototype(cfg, tables, [field["select"] for field in fields])
    set_query(query, tables, [field["select"] for field in fields])
    set_transforms(transforms, fields, {"Category"})
    return finish(vc, cfg, query, transforms)


def make_stacked_column(
    template: dict,
    category_table: str,
    category_col: str,
    category_label: str,
    series_table: str,
    series_col: str,
    series_label: str,
    measure: str,
    measure_label: str,
    fmt: str,
    x: float,
    y: float,
    w: float,
    h: float,
    z: int,
    tab: int,
) -> dict:
    vc, cfg, query, transforms = visual_base(template, x, y, w, h, z, tab)
    cfg["singleVisual"]["visualType"] = "stackedColumnChart"
    cfg["singleVisual"].setdefault("objects", {}).pop("dataPoint", None)
    cat = column_field("Category", category_table, category_col, category_label)
    series = column_field("Series", series_table, series_col, series_label)
    val = measure_field("Y", measure, measure_label, fmt)
    fields = [cat, series, val]
    cfg["singleVisual"]["projections"] = {
        "Category": [{"queryRef": cat["query_name"], "active": True}],
        "Series": [{"queryRef": series["query_name"], "active": True}],
        "Y": [{"queryRef": val["query_name"]}],
    }
    tables = list(dict.fromkeys([category_table, series_table, "_Measures"]))
    set_prototype(cfg, tables, [field["select"] for field in fields])
    set_query(query, tables, [field["select"] for field in fields])
    set_transforms(transforms, fields, {"Category", "Series"})
    return finish(vc, cfg, query, transforms)


def make_table(
    template: dict,
    fields: list[dict],
    x: float,
    y: float,
    w: float,
    h: float,
    z: int,
    tab: int,
) -> dict:
    vc, cfg, query, transforms = visual_base(template, x, y, w, h, z, tab)
    cfg["singleVisual"]["visualType"] = "tableEx"
    cfg["singleVisual"]["objects"] = {}
    for field in fields:
        field["role"] = "Values"
    cfg["singleVisual"]["projections"] = {"Values": [{"queryRef": field["query_name"]} for field in fields]}
    tables = list(dict.fromkeys([field["table"] for field in fields if field["kind"] != "measure"]))
    if any(field["kind"] == "measure" for field in fields):
        tables.append("_Measures")
    set_prototype(cfg, tables, [field["select"] for field in fields])
    set_query(query, tables, [field["select"] for field in fields])
    set_transforms(transforms, fields, {"Values"})
    return finish(vc, cfg, query, transforms)


def make_map(
    template: dict,
    x: float,
    y: float,
    w: float,
    h: float,
    z: int,
    tab: int,
) -> dict:
    vc, cfg, query, transforms = visual_base(template, x, y, w, h, z, tab)
    cfg["singleVisual"]["visualType"] = "map"
    cfg["singleVisual"]["objects"] = {}
    city = column_field("Category", "Dim_Geography", "city", "City", "City")
    lon = column_field("X", "Dim_Geography", "city_longitude", "Longitude")
    lat = column_field("Y", "Dim_Geography", "city_latitude", "Latitude")
    size = measure_field("Size", "Loan Exposure", "Loan Exposure", FMT_MONEY)
    rate = measure_field("Tooltips", "Default Rate", "Default Rate", FMT_PERCENT)
    exposure = measure_field("Tooltips", "Default Exposure", "Default Exposure", FMT_MONEY)
    fields = [city, lon, lat, size, rate, exposure]
    cfg["singleVisual"]["projections"] = {
        "Category": [{"queryRef": city["query_name"], "active": True}],
        "X": [{"queryRef": lon["query_name"]}],
        "Y": [{"queryRef": lat["query_name"]}],
        "Size": [{"queryRef": size["query_name"]}],
        "Tooltips": [{"queryRef": rate["query_name"]}, {"queryRef": exposure["query_name"]}],
    }
    set_prototype(cfg, ["Dim_Geography", "_Measures"], [field["select"] for field in fields])
    set_query(query, ["Dim_Geography", "_Measures"], [field["select"] for field in fields])
    set_transforms(transforms, fields, {"Category"})
    return finish(vc, cfg, query, transforms)


def make_scatter(
    template: dict,
    x: float,
    y: float,
    w: float,
    h: float,
    z: int,
    tab: int,
) -> dict:
    vc, cfg, query, transforms = visual_base(template, x, y, w, h, z, tab)
    cfg["singleVisual"]["visualType"] = "scatterChart"
    cfg["singleVisual"]["objects"] = {}
    detail = column_field("Category", "Fact_SegmentMembership", "segment_name", "Segment")
    xval = agg_field(
        "X",
        "Fact_SegmentMembership",
        "loan_exposure",
        SUM,
        sum_ref("Fact_SegmentMembership", "loan_exposure"),
        "Segment Exposure",
        FMT_MONEY,
    )
    yval = agg_field(
        "Y",
        "Fact_SegmentMembership",
        "loan_status",
        AVERAGE,
        avg_ref("Fact_SegmentMembership", "loan_status"),
        "Segment Default Rate",
        FMT_PERCENT,
    )
    size = agg_field(
        "Size",
        "Fact_SegmentMembership",
        "default_exposure",
        SUM,
        sum_ref("Fact_SegmentMembership", "default_exposure"),
        "Default Exposure",
        FMT_MONEY,
    )
    fields = [detail, xval, yval, size]
    cfg["singleVisual"]["projections"] = {
        "Category": [{"queryRef": detail["query_name"], "active": True}],
        "X": [{"queryRef": xval["query_name"]}],
        "Y": [{"queryRef": yval["query_name"]}],
        "Size": [{"queryRef": size["query_name"]}],
    }
    set_prototype(cfg, ["Fact_SegmentMembership"], [field["select"] for field in fields])
    set_query(query, ["Fact_SegmentMembership"], [field["select"] for field in fields])
    set_transforms(transforms, fields, {"Category"})
    return finish(vc, cfg, query, transforms)


def templates(layout: dict) -> dict:
    overview = next(sec for sec in layout["sections"] if sec["displayName"] == "Credit Risk Overview")
    out = {}
    for vc in overview["visualContainers"]:
        cfg = json.loads(vc["config"])
        vt = cfg["singleVisual"]["visualType"]
        out.setdefault(vt, vc)
    return {
        "textbox": out["textbox"],
        "slicer": out["slicer"],
        "card": out["cardVisual"],
        "bar": out["clusteredBarChart"],
        "column": out["clusteredColumnChart"],
    }


def reset_page(section: dict, title: str, t: dict) -> list[dict]:
    section["visualContainers"] = [make_text(t["textbox"], title, 0, 0, 1280, 48, 0, 0)]
    return section["visualContainers"]


def add_common_slicers(visuals: list[dict], t: dict, specs: list[tuple[str, str, str]], start_z: int, start_tab: int) -> tuple[int, int]:
    xs = [0, 272, 544, 816]
    widths = [176, 192, 192, 256]
    z, tab = start_z, start_tab
    for idx, (table, column, label) in enumerate(specs):
        visuals.append(make_slicer(t["slicer"], table, column, label, xs[idx], 48, widths[idx], 80, z, tab))
        z += 1
        tab += 1
    return z, tab


def complete_overview(section: dict, t: dict) -> None:
    visuals = section["visualContainers"]
    z = max(vc.get("z", 0) for vc in visuals) + 1
    tab = max(vc.get("tabOrder", 0) for vc in visuals if "tabOrder" in vc) + 1
    visuals.append(
        make_category_measure_chart(
            t["bar"],
            "clusteredBarChart",
            "Fact_loans",
            "pbi_affordability_group",
            "Affordability Group",
            "Default Rate",
            "Default Rate",
            FMT_PERCENT,
            624,
            448,
            480,
            192,
            z,
            tab,
        )
    )
    visuals.append(
        make_text(
            t["textbox"],
            "Top Risk Concentrations / Key Business Insights\nGrade D-G with high LTI/DTI and previous-default RENT borrowers drive the sharpest risk.\nUse Default Rate together with Default Exposure; segments overlap, so do not sum them as exclusive groups.",
            16,
            642,
            1088,
            72,
            z + 1,
            tab + 1,
            "10pt",
            False,
        )
    )


def build_borrower(section: dict, t: dict) -> None:
    visuals = reset_page(section, "BORROWER PROFILE", t)
    z, tab = add_common_slicers(
        visuals,
        t,
        [
            ("Fact_loans", "Loan Status Label", "Outcome"),
            ("Dim_Geography", "country", "Country"),
            ("Fact_loans", "loan_grade", "Loan Grade"),
            ("Fact_loans", "gender", "Gender"),
        ],
        1,
        1,
    )
    card_specs = [
        make_card_measure(t["card"], "Distinct Clients", "Borrowers", FMT_NUMBER, 0, 128, 248, 96, z, tab),
        make_card_agg(t["card"], "Fact_loans", "person_income", AVERAGE, avg_ref("Fact_loans", "person_income"), "Avg Income", FMT_MONEY, 264, 128, 248, 96, z + 1, tab + 1),
        make_card_agg(t["card"], "Fact_loans", "person_age", AVERAGE, avg_ref("Fact_loans", "person_age"), "Avg Age", FMT_DECIMAL, 528, 128, 248, 96, z + 2, tab + 2),
        make_card_agg(t["card"], "Fact_loans", "person_emp_length", AVERAGE, avg_ref("Fact_loans", "person_emp_length"), "Avg Employment", FMT_DECIMAL, 792, 128, 280, 96, z + 3, tab + 3),
    ]
    visuals.extend(card_specs)
    z += 4
    tab += 4
    charts = [
        ("pbi_age_band", "Age Band", 16, 240, 560, 160),
        ("pbi_income_band", "Income Band", 640, 240, 560, 160),
        ("person_home_ownership", "Home Ownership", 16, 420, 560, 130),
        ("pbi_employment_length_band", "Employment Length Band", 640, 420, 560, 130),
        ("education_level", "Education Level", 16, 570, 560, 130),
    ]
    for col, label, x, y, w, h in charts:
        visuals.append(make_category_measure_chart(t["bar"], "clusteredBarChart", "Fact_loans", col, label, "Default Rate", "Default Rate", FMT_PERCENT, x, y, w, h, z, tab))
        z += 1
        tab += 1
    visuals.append(make_stacked_column(t["column"], "Fact_loans", "pbi_income_band", "Income Band", "Fact_loans", "Loan Status Label", "Outcome", "Total Loans", "Total Loans", FMT_NUMBER, 640, 570, 560, 130, z, tab))


def build_affordability(section: dict, t: dict) -> None:
    visuals = reset_page(section, "LOAN & AFFORDABILITY RISK", t)
    z, tab = add_common_slicers(
        visuals,
        t,
        [
            ("Fact_loans", "loan_grade", "Grade"),
            ("Fact_loans", "loan_intent", "Intent"),
            ("Fact_loans", "pbi_affordability_group", "Affordability"),
            ("Fact_loans", "Loan Status Label", "Outcome"),
        ],
        1,
        1,
    )
    visuals.extend(
        [
            make_card_measure(t["card"], "Avg Loan Amount", "Avg Loan", FMT_MONEY, 0, 128, 248, 96, z, tab),
            make_card_measure(t["card"], "Avg Interest Rate", "Avg Rate", FMT_PERCENT, 264, 128, 248, 96, z + 1, tab + 1),
            make_card_agg(t["card"], "Fact_loans", "loan_to_income_ratio", AVERAGE, avg_ref("Fact_loans", "loan_to_income_ratio"), "Avg LTI", FMT_DECIMAL, 528, 128, 248, 96, z + 2, tab + 2),
            make_card_agg(t["card"], "Fact_loans", "debt_to_income_ratio", AVERAGE, avg_ref("Fact_loans", "debt_to_income_ratio"), "Avg DTI", FMT_DECIMAL, 792, 128, 280, 96, z + 3, tab + 3),
        ]
    )
    z += 4
    tab += 4
    charts = [
        ("loan_grade", "Loan Grade", 16, 240, 360, 150),
        ("pbi_interest_rate_band", "Interest Rate Band", 440, 240, 360, 150),
        ("pbi_lti_band", "LTI Band", 840, 240, 360, 150),
        ("pbi_dti_band", "DTI Band", 16, 410, 360, 140),
        ("pbi_affordability_group", "Affordability Group", 440, 410, 360, 140),
    ]
    for col, label, x, y, w, h in charts:
        visuals.append(make_category_measure_chart(t["column"], "clusteredColumnChart", "Fact_loans", col, label, "Default Rate", "Default Rate", FMT_PERCENT, x, y, w, h, z, tab))
        z += 1
        tab += 1
    visuals.append(make_text(t["textbox"], "LTI x DTI Risk Matrix", 840, 410, 360, 30, z, tab, "12pt", True))
    z += 1
    tab += 1
    visuals.append(
        make_table(
            t["bar"],
            [
                column_field("Values", "Fact_loans", "pbi_lti_band", "LTI Band"),
                column_field("Values", "Fact_loans", "pbi_dti_band", "DTI Band"),
                measure_field("Values", "Total Loans", "Loans", FMT_NUMBER),
                measure_field("Values", "Default Rate", "Default Rate", FMT_PERCENT),
                measure_field("Values", "Default Exposure", "Default Exposure", FMT_MONEY),
            ],
            840,
            440,
            360,
            110,
            z,
            tab,
        )
    )
    z += 1
    tab += 1
    visuals.append(
        make_category_measure_chart(
            t["bar"],
            "clusteredBarChart",
            "Fact_loans",
            "pbi_affordability_group",
            "Affordability Group",
            "Default Rate",
            "Default Rate",
            FMT_PERCENT,
            16,
            570,
            1184,
            130,
            z,
            tab,
        )
    )


def build_credit_geo(section: dict, t: dict) -> None:
    visuals = reset_page(section, "CREDIT PROFILE & GEOGRAPHY", t)
    z, tab = add_common_slicers(
        visuals,
        t,
        [
            ("Dim_Geography", "country", "Country"),
            ("Dim_Geography", "state", "State"),
            ("Fact_loans", "Loan Status Label", "Outcome"),
            ("Fact_loans", "pbi_previous_default_label", "Previous Default"),
        ],
        1,
        1,
    )
    visuals.extend(
        [
            make_card_agg(t["card"], "Fact_loans", "cb_person_cred_hist_length", AVERAGE, avg_ref("Fact_loans", "cb_person_cred_hist_length"), "Avg Credit History", FMT_DECIMAL, 0, 128, 280, 96, z, tab),
            make_card_agg(t["card"], "Fact_loans", "credit_utilization_ratio", AVERAGE, avg_ref("Fact_loans", "credit_utilization_ratio"), "Avg Utilization", FMT_DECIMAL, 304, 128, 280, 96, z + 1, tab + 1),
            make_card_agg(t["card"], "Fact_loans", "pbi_flag_previous_default", AVERAGE, avg_ref("Fact_loans", "pbi_flag_previous_default"), "Previous Default Rate", FMT_PERCENT, 608, 128, 320, 96, z + 2, tab + 2),
        ]
    )
    z += 3
    tab += 3
    charts = [
        ("pbi_credit_history_band", "Credit History Band", 16, 240, 560, 150),
        ("pbi_previous_default_label", "Previous Default", 640, 240, 560, 150),
        ("pbi_utilization_band", "Utilization Band", 16, 410, 560, 140),
        ("pbi_delinquency_band", "Delinquency Band", 640, 410, 560, 140),
    ]
    for col, label, x, y, w, h in charts:
        visuals.append(make_category_measure_chart(t["bar"], "clusteredBarChart", "Fact_loans", col, label, "Default Rate", "Default Rate", FMT_PERCENT, x, y, w, h, z, tab))
        z += 1
        tab += 1
    visuals.append(make_map(t["bar"], 16, 570, 560, 130, z, tab))
    z += 1
    tab += 1
    visuals.append(
        make_table(
            t["bar"],
            [
                column_field("Values", "Dim_Geography", "country", "Country"),
                column_field("Values", "Dim_Geography", "state", "State"),
                column_field("Values", "Dim_Geography", "city", "City"),
                measure_field("Values", "Loan Exposure", "Loan Exposure", FMT_MONEY),
                measure_field("Values", "Default Rate", "Default Rate", FMT_PERCENT),
                measure_field("Values", "Default Exposure", "Default Exposure", FMT_MONEY),
            ],
            640,
            570,
            560,
            130,
            z,
            tab,
        )
    )


def build_segmentation(section: dict, t: dict) -> None:
    visuals = reset_page(section, "RISK SEGMENTATION", t)
    z, tab = add_common_slicers(
        visuals,
        t,
        [
            ("Fact_SegmentMembership", "segment_family", "Segment Family"),
            ("Fact_SegmentMembership", "segment_type", "Segment Type"),
            ("Dim_Geography", "country", "Country"),
        ],
        1,
        1,
    )
    visuals.extend(
        [
            make_card_agg(t["card"], "Fact_SegmentMembership", "segment_name", DISTINCT_COUNT, distinct_count_ref("Fact_SegmentMembership", "segment_name"), "Segment Count", FMT_NUMBER, 0, 128, 248, 96, z, tab),
            make_card_agg(t["card"], "Fact_SegmentMembership", "loan_count", SUM, sum_ref("Fact_SegmentMembership", "loan_count"), "Loans", FMT_NUMBER, 264, 128, 248, 96, z + 1, tab + 1),
            make_card_agg(t["card"], "Fact_SegmentMembership", "loan_status", AVERAGE, avg_ref("Fact_SegmentMembership", "loan_status"), "Default Rate", FMT_PERCENT, 528, 128, 248, 96, z + 2, tab + 2),
            make_card_agg(t["card"], "Fact_SegmentMembership", "default_exposure", SUM, sum_ref("Fact_SegmentMembership", "default_exposure"), "Default Exposure", FMT_MONEY, 792, 128, 280, 96, z + 3, tab + 3),
        ]
    )
    z += 4
    tab += 4
    visuals.append(make_category_agg_chart(t["bar"], "clusteredBarChart", "Fact_SegmentMembership", "segment_name", "Segment", "Fact_SegmentMembership", "loan_status", AVERAGE, avg_ref("Fact_SegmentMembership", "loan_status"), "Segment Default Rate", FMT_PERCENT, 16, 240, 560, 150, z, tab))
    z += 1
    tab += 1
    visuals.append(make_category_agg_chart(t["bar"], "clusteredBarChart", "Fact_SegmentMembership", "segment_name", "Segment", "Fact_SegmentMembership", "loan_count", SUM, sum_ref("Fact_SegmentMembership", "loan_count"), "Segment Volume", FMT_NUMBER, 640, 240, 560, 150, z, tab))
    z += 1
    tab += 1
    visuals.append(make_category_agg_chart(t["bar"], "clusteredBarChart", "Fact_SegmentMembership", "segment_name", "Segment", "Fact_SegmentMembership", "default_exposure", SUM, sum_ref("Fact_SegmentMembership", "default_exposure"), "Default Exposure", FMT_MONEY, 16, 410, 560, 140, z, tab))
    z += 1
    tab += 1
    visuals.append(make_scatter(t["bar"], 640, 410, 560, 140, z, tab))
    z += 1
    tab += 1
    visuals.append(
        make_table(
            t["bar"],
            [
                column_field("Values", "Fact_SegmentMembership", "segment_name", "Segment"),
                column_field("Values", "Fact_SegmentMembership", "segment_family", "Family"),
                column_field("Values", "Fact_SegmentMembership", "segment_type", "Type"),
                agg_field("Values", "Fact_SegmentMembership", "loan_count", SUM, sum_ref("Fact_SegmentMembership", "loan_count"), "Loans", FMT_NUMBER),
                agg_field("Values", "Fact_SegmentMembership", "loan_status", AVERAGE, avg_ref("Fact_SegmentMembership", "loan_status"), "Default Rate", FMT_PERCENT),
                agg_field("Values", "Fact_SegmentMembership", "default_exposure", SUM, sum_ref("Fact_SegmentMembership", "default_exposure"), "Default Exposure", FMT_MONEY),
            ],
            16,
            570,
            1184,
            130,
            z,
            tab,
        )
    )


def update_layout(layout: dict) -> dict:
    t = templates(layout)
    sections = {section["displayName"]: section for section in layout["sections"]}
    complete_overview(sections["Credit Risk Overview"], t)
    sections["Borrower Profie"]["displayName"] = "Borrower Profile"
    build_borrower(sections["Borrower Profie"], t)
    build_affordability(sections["Loan & Affordability Risk"], t)
    build_credit_geo(sections["Credit Profile & Geography"], t)
    build_segmentation(sections["Risk Segmentation & Recommendations"], t)
    return layout


def output_path() -> Path:
    return PBIX_OUT


def main() -> None:
    out = output_path()
    with zipfile.ZipFile(PBIX_IN, "r") as zin:
        layout = decode_layout(zin.read("Report/Layout"))
        layout = update_layout(layout)
        new_layout = encode_layout(layout)
        with zipfile.ZipFile(out, "w") as zout:
            for info in zin.infolist():
                if info.filename == "SecurityBindings":
                    continue
                data = new_layout if info.filename == "Report/Layout" else zin.read(info.filename)
                new_info = zipfile.ZipInfo(info.filename, info.date_time)
                new_info.compress_type = info.compress_type
                new_info.external_attr = info.external_attr
                new_info.internal_attr = info.internal_attr
                new_info.comment = info.comment
                zout.writestr(new_info, data)
    counts = {section["displayName"]: len(section["visualContainers"]) for section in layout["sections"]}
    print(out)
    for page, count in counts.items():
        print(f"{page}: {count} visuals")


if __name__ == "__main__":
    main()
