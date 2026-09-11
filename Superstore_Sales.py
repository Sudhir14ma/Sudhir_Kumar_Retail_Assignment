import numpy as np
import pandas as pd

# 1. Load the dataset
# Adjust filename if your downloaded file has a different name
df = pd.read_csv("Superstore Sales Dataset.csv", encoding="latin1")

# Create an audit log list to capture every operation
audit_log = []

# --- Step 1: Duplicate Handling ---
initial_rows = len(df)
# Check for exact row-level duplicates
exact_dupes = df.duplicated().sum()
if exact_dupes > 0:
    df = df.drop_duplicates()
audit_log.append(
    {
        "Step": "Exact Duplicates Check",
        "Records Impacted": int(exact_dupes),
        "Action Taken": "Dropped identical duplicate rows",
    }
)

# Note on Order ID: Multiple rows share the same Order ID because orders contain multiple items.
# We verify duplicate line items per order (Order ID + Product ID)
line_item_dupes = df.duplicated(subset=["Order ID", "Product ID"]).sum()
if line_item_dupes > 0:
    df = df.drop_duplicates(subset=["Order ID", "Product ID"], keep="first")
audit_log.append(
    {
        "Step": "Duplicate Line Items (Order ID + Product ID)",
        "Records Impacted": int(line_item_dupes),
        "Action Taken": "Retained first entry per unique order line item",
    }
)

# --- Step 2: Date Parsing ---
df["Order Date"] = pd.to_datetime(df["Order Date"], errors="coerce")
df["Ship Date"] = pd.to_datetime(df["Ship Date"], errors="coerce")

invalid_order_dates = df["Order Date"].isna().sum()
invalid_ship_dates = df["Ship Date"].isna().sum()
audit_log.append(
    {
        "Step": "Datetime Standardization",
        "Records Impacted": int(invalid_order_dates + invalid_ship_dates),
        "Action Taken": "Standardized Order Date and Ship Date to ISO datetime format (YYYY-MM-DD)",
    }
)

# --- Step 3: Numeric Conversion & Data Types ---
numeric_cols = ["Sales", "Quantity", "Discount", "Profit"]
for col in numeric_cols:
    df[col] = pd.to_numeric(df[col], errors="coerce")

# Handle Postal Code: Convert to clean string to avoid floating-point artifacts
if "Postal Code" in df.columns:
    df["Postal Code"] = (
        df["Postal Code"].fillna(0).astype(int).astype(str).str.zfill(5)
    )

audit_log.append(
    {
        "Step": "Numeric Type Casting",
        "Records Impacted": 0,
        "Action Taken": "Cast Sales, Quantity, Discount, and Profit to float/int",
    }
)

# --- Step 4: Missing Value Imputation / Audit ---
null_summary = df[numeric_cols].isna().sum().sum()
if null_summary > 0:
    df = df.dropna(subset=numeric_cols)
audit_log.append(
    {
        "Step": "Missing Value Validation",
        "Records Impacted": int(null_summary),
        "Action Taken": "Removed rows with missing core metrics (if any existed)",
    }
)

# --- Step 5: Feature Engineering ---
# Profit Margin = Profit / Sales (safely handle zero or near-zero sales if present)
df["profit_margin"] = np.where(
    df["Sales"] != 0, (df["Profit"] / df["Sales"]).round(4), 0.0
)

# Extracted order_month in YYYY-MM format
df["order_month"] = df["Order Date"].dt.to_period("M").astype(str)

# Loss Flag: 1 if Profit < 0 else 0
df["loss_flag"] = np.where(df["Profit"] < 0, 1, 0)

audit_log.append(
    {
        "Step": "Feature Engineering",
        "Records Impacted": len(df),
        "Action Taken": "Created profit_margin, order_month (YYYY-MM), and binary loss_flag",
    }
)

# --- Step 6: Export Deliverables ---
# Cleaned CSV
df.to_csv("retail_clean.csv", index=False)

# Cleaning Log Excel
log_df = pd.DataFrame(audit_log)
with pd.ExcelWriter("cleaning_log.xlsx", engine="openpyxl") as writer:
    log_df.to_excel(writer, sheet_name="Cleaning Audit", index=False)
    # Add a metadata summary sheet
    summary_df = pd.DataFrame(
        {
            "Metric": [
                "Total Rows Processed",
                "Clean Rows Exported",
                "Total Sales ($)",
                "Total Profit ($)",
                "Loss-Making Transactions",
            ],
            "Value": [
                initial_rows,
                len(df),
                df["Sales"].sum().round(2),
                df["Profit"].sum().round(2),
                df["loss_flag"].sum(),
            ],
        }
    )
    summary_df.to_excel(writer, sheet_name="Dataset Summary", index=False)

print(
    f"Complete. Clean rows: {len(df)}. Files generated: retail_clean.csv, cleaning_log.xlsx"
)