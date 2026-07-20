"""
Enterprise Retail Analytics Platform - Synthetic Dataset Generator
=================================================================

Generates deterministic, enterprise-scale retail data with intentional
data-quality defects for ETL/staging demonstration.

Usage:
    python generate_dataset.py --profile development
    python generate_dataset.py --profile production
    python generate_dataset.py --profile development --output ../Dataset

Profiles:
    development : 50,000 orders (~200K detail rows) - fast local testing
    production  : 500,000 orders (2,000,000 detail rows) - full-scale

Author: BI Development Team
"""

from __future__ import annotations

import argparse
import os
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import List

import numpy as np
import pandas as pd
from faker import Faker

# =============================================================================
# CONFIGURATION
# =============================================================================

MASTER_SEED = 42  # Deterministic reproducibility


@dataclass
class Profile:
    """Generation profile controlling volume and defect injection."""

    name: str
    num_orders: int
    avg_lines_per_order: float
    num_customers: int
    num_products: int
    num_stores: int
    num_employees: int
    num_suppliers: int
    num_categories: int
    num_subcategories: int
    date_start: str = "2021-01-01"
    date_end: str = "2025-12-31"
    return_rate: float = 0.05
    # Defect injection rates
    defect_null_email_rate: float = 0.05
    defect_duplicate_order_rate: float = 0.005
    defect_future_date_rate: float = 0.001
    defect_orphan_product_rate: float = 0.002
    defect_inconsistent_category_rate: float = 0.03
    defect_negative_quantity_rate: float = 0.001



PROFILES = {
    "development": Profile(
        name="development",
        num_orders=50_000,
        avg_lines_per_order=4.0,
        num_customers=20_000,
        num_products=2_000,
        num_stores=50,
        num_employees=1_000,
        num_suppliers=100,
        num_categories=5,
        num_subcategories=25,
    ),
    "production": Profile(
        name="production",
        num_orders=500_000,
        avg_lines_per_order=4.0,
        num_customers=200_000,
        num_products=10_000,
        num_stores=120,
        num_employees=5_000,
        num_suppliers=500,
        num_categories=5,
        num_subcategories=50,
    ),
}

# =============================================================================
# REFERENCE DATA
# =============================================================================

REGIONS = [
    {"RegionID": 1, "RegionName": "East"},
    {"RegionID": 2, "RegionName": "West"},
    {"RegionID": 3, "RegionName": "North"},
    {"RegionID": 4, "RegionName": "South"},
]

STATES_BY_REGION = {
    "East": ["New York", "Pennsylvania", "New Jersey", "Massachusetts",
             "Connecticut", "Virginia", "Maryland", "Florida", "Georgia"],
    "West": ["California", "Washington", "Oregon", "Nevada", "Arizona",
             "Colorado", "Utah", "Hawaii"],
    "North": ["Illinois", "Ohio", "Michigan", "Minnesota", "Wisconsin",
              "Indiana", "Iowa", "Missouri"],
    "South": ["Texas", "Tennessee", "North Carolina", "South Carolina",
              "Alabama", "Louisiana", "Mississippi", "Oklahoma", "Arkansas"],
}


CATEGORY_DEFINITIONS = [
    {"CategoryName": "Electronics", "SubCategories": [
        "Laptops", "Desktops", "Tablets", "Monitors", "Printers",
        "Cameras", "Audio", "Networking", "Storage", "Components"]},
    {"CategoryName": "Home & Kitchen", "SubCategories": [
        "Appliances", "Cookware", "Dining", "Bedding", "Bath",
        "Lighting", "Decor", "Cleaning", "Organization", "Garden"]},
    {"CategoryName": "Office Supplies", "SubCategories": [
        "Paper", "Pens & Markers", "Binders", "Labels", "Envelopes",
        "Notebooks", "Desk Accessories", "Calendars", "Tape & Adhesives", "Scissors"]},
    {"CategoryName": "Furniture", "SubCategories": [
        "Desks", "Chairs", "Bookcases", "Tables", "Filing Cabinets",
        "Shelving", "Office Sets", "Outdoor", "Bedroom", "Living Room"]},
    {"CategoryName": "Technology Accessories", "SubCategories": [
        "Cables", "Cases", "Chargers", "Screen Protectors", "Keyboards",
        "Mice", "Headsets", "Webcams", "USB Hubs", "Stands"]},
]

CHANNELS = ["Store", "E-commerce"]
ORDER_STATUSES = ["Completed", "Shipped", "Processing", "Cancelled"]
RETURN_REASONS = [
    "Defective", "Wrong Item", "Not as Described", "Changed Mind",
    "Arrived Late", "Better Price Found", "Duplicate Order",
]
RETURN_CONDITIONS = ["New", "Open Box", "Damaged", "Used"]
CARRIERS = ["FedEx", "UPS", "USPS", "DHL", "ShopStar Logistics"]
SHIP_MODES = ["Standard", "Express", "Same Day", "Economy"]

CUSTOMER_SEGMENTS = ["Consumer Standard", "Consumer Premium", "Small Business", "Enterprise"]
DEPARTMENTS = ["Sales", "Operations", "Management", "Warehouse", "Customer Service"]
ROLES_BY_DEPT = {
    "Sales": ["Sales Associate", "Senior Sales Associate", "Sales Lead"],
    "Operations": ["Operations Clerk", "Operations Specialist", "Operations Manager"],
    "Management": ["Store Manager", "Assistant Manager", "Regional Manager"],
    "Warehouse": ["Warehouse Associate", "Inventory Specialist", "Warehouse Lead"],
    "Customer Service": ["CS Representative", "CS Lead", "CS Manager"],
}



# =============================================================================
# GENERATOR CLASS
# =============================================================================


class RetailDataGenerator:
    """Generates all 12 source CSV files for the retail analytics platform."""

    def __init__(self, profile: Profile, output_dir: Path):
        self.profile = profile
        self.output_dir = output_dir
        self.rng = np.random.default_rng(MASTER_SEED)
        self.fake = Faker("en_US")
        Faker.seed(MASTER_SEED)
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Internal state populated during generation
        self._categories_df: pd.DataFrame = pd.DataFrame()
        self._products_df: pd.DataFrame = pd.DataFrame()
        self._customers_df: pd.DataFrame = pd.DataFrame()
        self._stores_df: pd.DataFrame = pd.DataFrame()
        self._employees_df: pd.DataFrame = pd.DataFrame()
        self._suppliers_df: pd.DataFrame = pd.DataFrame()
        self._regions_df: pd.DataFrame = pd.DataFrame()
        self._orders_df: pd.DataFrame = pd.DataFrame()
        self._order_details_df: pd.DataFrame = pd.DataFrame()

    def generate_all(self) -> None:
        """Execute full generation pipeline in dependency order."""
        print(f"{'='*60}")
        print(f"  ShopStar Retail - Synthetic Data Generator")
        print(f"  Profile: {self.profile.name}")
        print(f"  Output:  {self.output_dir.resolve()}")
        print(f"{'='*60}\n")

        self._gen_regions()
        self._gen_categories()
        self._gen_suppliers()
        self._gen_products()
        self._gen_stores()
        self._gen_employees()
        self._gen_customers()
        self._gen_orders()
        self._gen_order_details()
        self._gen_returns()
        self._gen_shipping()
        self._gen_inventory()

        print(f"\n{'='*60}")
        print(f"  Generation complete. Files saved to: {self.output_dir.resolve()}")
        print(f"{'='*60}")


    # -------------------------------------------------------------------------
    # Dimension Generators
    # -------------------------------------------------------------------------

    def _gen_regions(self) -> None:
        """Generate regions.csv — 4 US regions."""
        print("[1/12] Generating regions.csv ...")
        self._regions_df = pd.DataFrame(REGIONS)
        self._regions_df.to_csv(self.output_dir / "regions.csv", index=False, encoding="utf-8")
        print(f"        → {len(self._regions_df)} rows")

    def _gen_categories(self) -> None:
        """Generate categories.csv with intentional case-inconsistency defects."""
        print("[2/12] Generating categories.csv ...")
        rows = []
        cat_id = 1
        defect_injected = False
        for cat_def in CATEGORY_DEFINITIONS:
            for sub in cat_def["SubCategories"][: self.profile.num_subcategories // self.profile.num_categories]:
                cat_name = cat_def["CategoryName"]
                # DEFECT: Inject inconsistent casing on a subset of rows
                if self.rng.random() < self.profile.defect_inconsistent_category_rate:
                    variant = self.rng.choice(["upper", "lower", "mixed"])
                    if variant == "upper":
                        cat_name = cat_name.upper()
                    elif variant == "lower":
                        cat_name = cat_name.lower()
                    else:
                        cat_name = cat_name.swapcase()
                    defect_injected = True
                rows.append({
                    "CategoryID": cat_id,
                    "CategoryName": cat_name,
                    "SubCategoryName": sub,
                    "Department": "Retail",
                })
                cat_id += 1
        # Guarantee at least one casing defect exists
        if not defect_injected and len(rows) > 0:
            idx = int(self.rng.integers(0, len(rows)))
            rows[idx]["CategoryName"] = rows[idx]["CategoryName"].upper()
        self._categories_df = pd.DataFrame(rows)
        self._categories_df.to_csv(self.output_dir / "categories.csv", index=False, encoding="utf-8")
        print(f"        → {len(self._categories_df)} rows")

    def _gen_suppliers(self) -> None:
        """Generate suppliers.csv."""
        print("[3/12] Generating suppliers.csv ...")
        rows = []
        for i in range(1, self.profile.num_suppliers + 1):
            rows.append({
                "SupplierID": i,
                "SupplierName": self.fake.company(),
                "Country": self.rng.choice(["USA", "China", "Germany", "Japan", "India",
                                            "Mexico", "South Korea", "Taiwan"]),
                "LeadTimeDays": int(self.rng.integers(3, 45)),
                "Rating": round(float(self.rng.uniform(2.5, 5.0)), 1),
                "ContactEmail": self.fake.company_email(),
            })
        self._suppliers_df = pd.DataFrame(rows)
        self._suppliers_df.to_csv(self.output_dir / "suppliers.csv", index=False, encoding="utf-8")
        print(f"        → {len(self._suppliers_df)} rows")


    def _gen_products(self) -> None:
        """Generate products.csv with cost/price relationships."""
        print("[4/12] Generating products.csv ...")
        rows = []
        num_cats = len(self._categories_df)
        for i in range(1, self.profile.num_products + 1):
            cat_row = self._categories_df.iloc[i % num_cats]
            unit_cost = round(float(self.rng.uniform(5.0, 800.0)), 2)
            margin = float(self.rng.uniform(0.15, 0.65))
            unit_price = round(unit_cost * (1 + margin), 2)
            rows.append({
                "ProductID": i,
                "ProductName": f"{cat_row['SubCategoryName']} - {self.fake.bothify('?? ####')}",
                "CategoryID": int(cat_row["CategoryID"]),
                "Category": cat_row["CategoryName"],
                "SubCategory": cat_row["SubCategoryName"],
                "Brand": self.fake.company().split()[0],
                "UnitCost": unit_cost,
                "UnitPrice": unit_price,
                "SupplierID": int(self.rng.integers(1, self.profile.num_suppliers + 1)),
            })
        self._products_df = pd.DataFrame(rows)
        self._products_df.to_csv(self.output_dir / "products.csv", index=False, encoding="utf-8")
        print(f"        → {len(self._products_df)} rows")

    def _gen_stores(self) -> None:
        """Generate stores.csv with geographic distribution."""
        print("[5/12] Generating stores.csv ...")
        rows = []
        all_states = []
        for region, states in STATES_BY_REGION.items():
            for state in states:
                all_states.append((region, state))
        for i in range(1, self.profile.num_stores + 1):
            region, state = all_states[i % len(all_states)]
            open_year = int(self.rng.integers(2005, 2022))
            rows.append({
                "StoreID": i,
                "StoreName": f"ShopStar #{i:04d}",
                "City": self.fake.city(),
                "State": state,
                "Region": region,
                "StoreType": self.rng.choice(["Full-Size", "Express", "Outlet"]),
                "OpenDate": f"{open_year}-{int(self.rng.integers(1,13)):02d}-01",
                "SquareFootage": int(self.rng.integers(8000, 65000)),
            })
        self._stores_df = pd.DataFrame(rows)
        self._stores_df.to_csv(self.output_dir / "stores.csv", index=False, encoding="utf-8")
        print(f"        → {len(self._stores_df)} rows")


    def _gen_employees(self) -> None:
        """Generate employees.csv with hierarchy (ManagerID NULL for top-level)."""
        print("[6/12] Generating employees.csv ...")
        rows = []
        for i in range(1, self.profile.num_employees + 1):
            dept = self.rng.choice(DEPARTMENTS)
            role = self.rng.choice(ROLES_BY_DEPT[dept])
            store_id = int(self.rng.integers(1, self.profile.num_stores + 1))
            hire_year = int(self.rng.integers(2005, 2025))
            # Top-level managers (first 5%) have no manager → NULL defect demonstration
            manager_id = None if i <= int(self.profile.num_employees * 0.05) else int(
                self.rng.integers(1, max(2, int(self.profile.num_employees * 0.05) + 1))
            )
            salary = int(self.rng.integers(30000, 150000))
            rows.append({
                "EmployeeID": i,
                "FirstName": self.fake.first_name(),
                "LastName": self.fake.last_name(),
                "Department": dept,
                "Role": role,
                "StoreID": store_id,
                "HireDate": f"{hire_year}-{int(self.rng.integers(1,13)):02d}-{int(self.rng.integers(1,29)):02d}",
                "Salary": salary,
                "ManagerID": manager_id,
            })
        self._employees_df = pd.DataFrame(rows)
        self._employees_df.to_csv(self.output_dir / "employees.csv", index=False, encoding="utf-8")
        print(f"        → {len(self._employees_df)} rows")

    def _gen_customers(self) -> None:
        """Generate customers.csv with NULL email defects."""
        print("[7/12] Generating customers.csv ...")
        rows = []
        all_states = []
        for region, states in STATES_BY_REGION.items():
            for state in states:
                all_states.append((region, state))
        for i in range(1, self.profile.num_customers + 1):
            region, state = all_states[i % len(all_states)]
            join_year = int(self.rng.integers(2018, 2026))
            # DEFECT: ~5% of emails are NULL
            email = None if self.rng.random() < self.profile.defect_null_email_rate else self.fake.email()
            rows.append({
                "CustomerID": i,
                "FirstName": self.fake.first_name(),
                "LastName": self.fake.last_name(),
                "Email": email,
                "Segment": self.rng.choice(CUSTOMER_SEGMENTS),
                "JoinDate": f"{join_year}-{int(self.rng.integers(1,13)):02d}-{int(self.rng.integers(1,29)):02d}",
                "City": self.fake.city(),
                "State": state,
                "Region": region,
            })
        self._customers_df = pd.DataFrame(rows)
        self._customers_df.to_csv(self.output_dir / "customers.csv", index=False, encoding="utf-8")
        print(f"        → {len(self._customers_df)} rows")


    # -------------------------------------------------------------------------
    # Fact Table Generators
    # -------------------------------------------------------------------------

    def _gen_orders(self) -> None:
        """Generate orders.csv with seasonal patterns, duplicate & future-date defects."""
        print("[8/12] Generating orders.csv ...")
        start = pd.Timestamp(self.profile.date_start)
        end = pd.Timestamp(self.profile.date_end)
        total_days = (end - start).days

        # Generate order dates with seasonality (Q4 peak)
        day_offsets = self.rng.integers(0, total_days, size=self.profile.num_orders)
        dates = [start + pd.Timedelta(days=int(d)) for d in day_offsets]

        # Apply Q4 weighting by oversampling Oct-Dec
        q4_boost = int(self.profile.num_orders * 0.15)
        q4_start_offset = (pd.Timestamp(f"2023-10-01") - start).days
        q4_end_offset = (pd.Timestamp(f"2023-12-31") - start).days
        for _ in range(q4_boost):
            offset = int(self.rng.integers(max(0, q4_start_offset), min(total_days, q4_end_offset + 1)))
            year_shift = int(self.rng.choice([0, 365, 730, -365, -730]))
            final_offset = max(0, min(total_days - 1, offset + year_shift))
            dates.append(start + pd.Timedelta(days=final_offset))

        dates = dates[: self.profile.num_orders]  # Trim to exact count

        rows = []
        for i in range(self.profile.num_orders):
            order_date = dates[i]

            # DEFECT: ~0.1% future dates (beyond 2025-12-31)
            if self.rng.random() < self.profile.defect_future_date_rate:
                order_date = pd.Timestamp("2027-03-15")

            channel = self.rng.choice(CHANNELS, p=[0.6, 0.4])
            store_id = int(self.rng.integers(1, self.profile.num_stores + 1)) if channel == "Store" else None
            employee_id = int(self.rng.integers(1, self.profile.num_employees + 1)) if channel == "Store" else None

            rows.append({
                "OrderID": i + 1,
                "CustomerID": int(self.rng.integers(1, self.profile.num_customers + 1)),
                "OrderDate": order_date.strftime("%Y-%m-%d"),
                "StoreID": store_id,
                "EmployeeID": employee_id,
                "Channel": channel,
                "Status": self.rng.choice(ORDER_STATUSES, p=[0.85, 0.08, 0.04, 0.03]),
            })

        self._orders_df = pd.DataFrame(rows)

        # DEFECT: Inject ~0.5% duplicate rows (exact copies)
        num_dupes = int(len(self._orders_df) * self.profile.defect_duplicate_order_rate)
        if num_dupes > 0:
            dupe_indices = self.rng.integers(0, len(self._orders_df), size=num_dupes)
            dupes = self._orders_df.iloc[dupe_indices].copy()
            self._orders_df = pd.concat([self._orders_df, dupes], ignore_index=True)

        self._orders_df.to_csv(self.output_dir / "orders.csv", index=False, encoding="utf-8")
        print(f"        → {len(self._orders_df)} rows (includes {num_dupes} intentional duplicates)")


    def _gen_order_details(self) -> None:
        """Generate order_details.csv with orphan product refs and negative qty defects."""
        print("[9/12] Generating order_details.csv ...")
        rows = []
        detail_id = 1
        max_product_id = self.profile.num_products

        # Phantom product IDs for orphan defect (IDs beyond valid range)
        phantom_start = max_product_id + 1
        phantom_end = max_product_id + 50

        for _, order in self._orders_df.iterrows():
            num_lines = max(1, int(self.rng.poisson(self.profile.avg_lines_per_order - 1)) + 1)
            for _ in range(num_lines):
                product_id = int(self.rng.integers(1, max_product_id + 1))

                # DEFECT: ~0.2% orphan product references
                if self.rng.random() < self.profile.defect_orphan_product_rate:
                    product_id = int(self.rng.integers(phantom_start, phantom_end + 1))

                quantity = int(self.rng.integers(1, 15))

                # DEFECT: ~0.1% negative quantities
                if self.rng.random() < self.profile.defect_negative_quantity_rate:
                    quantity = -abs(quantity)

                # Look up price (use fallback for phantom products)
                if product_id <= max_product_id:
                    unit_price = float(self._products_df.iloc[product_id - 1]["UnitPrice"])
                else:
                    unit_price = round(float(self.rng.uniform(10, 500)), 2)

                discount = round(float(self.rng.choice(
                    [0, 0, 0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35]
                )), 2)
                line_total = round(quantity * unit_price * (1 - discount), 2)

                rows.append({
                    "OrderDetailID": detail_id,
                    "OrderID": order["OrderID"],
                    "ProductID": product_id,
                    "Quantity": quantity,
                    "UnitPrice": unit_price,
                    "Discount": discount,
                    "LineTotal": line_total,
                })
                detail_id += 1

        self._order_details_df = pd.DataFrame(rows)
        self._order_details_df.to_csv(self.output_dir / "order_details.csv", index=False, encoding="utf-8")
        print(f"        → {len(self._order_details_df)} rows")


    def _gen_returns(self) -> None:
        """Generate returns.csv — subset of completed order details."""
        print("[10/12] Generating returns.csv ...")
        completed_details = self._order_details_df[
            self._order_details_df["OrderID"].isin(
                self._orders_df[self._orders_df["Status"] == "Completed"]["OrderID"]
            )
        ]
        num_returns = int(len(completed_details) * self.profile.return_rate)
        return_indices = self.rng.choice(len(completed_details), size=num_returns, replace=False)
        return_details = completed_details.iloc[return_indices]

        rows = []
        for idx, (_, detail) in enumerate(return_details.iterrows(), 1):
            order_date = self._orders_df[
                self._orders_df["OrderID"] == detail["OrderID"]
            ]["OrderDate"].iloc[0]
            return_offset = int(self.rng.integers(1, 60))
            return_date = (pd.Timestamp(order_date) + pd.Timedelta(days=return_offset)).strftime("%Y-%m-%d")
            refund_amount = round(abs(float(detail["LineTotal"])) * float(self.rng.uniform(0.5, 1.0)), 2)

            rows.append({
                "ReturnID": idx,
                "OrderDetailID": int(detail["OrderDetailID"]),
                "ReturnDate": return_date,
                "Reason": self.rng.choice(RETURN_REASONS),
                "RefundAmount": refund_amount,
                "Condition": self.rng.choice(RETURN_CONDITIONS),
            })

        returns_df = pd.DataFrame(rows)
        returns_df.to_csv(self.output_dir / "returns.csv", index=False, encoding="utf-8")
        print(f"        → {len(returns_df)} rows")

    def _gen_shipping(self) -> None:
        """Generate shipping.csv for e-commerce and shipped store orders."""
        print("[11/12] Generating shipping.csv ...")
        shippable = self._orders_df[
            (self._orders_df["Channel"] == "E-commerce") |
            (self._orders_df["Status"] == "Shipped")
        ].copy()

        rows = []
        for idx, (_, order) in enumerate(shippable.iterrows(), 1):
            order_date = pd.Timestamp(order["OrderDate"])
            ship_delay = int(self.rng.integers(0, 5))
            ship_date = order_date + pd.Timedelta(days=ship_delay)
            transit_days = int(self.rng.integers(1, 14))
            delivery_date = ship_date + pd.Timedelta(days=transit_days)
            shipping_cost = round(float(self.rng.uniform(3.99, 29.99)), 2)

            rows.append({
                "ShippingID": idx,
                "OrderID": int(order["OrderID"]),
                "ShipDate": ship_date.strftime("%Y-%m-%d"),
                "DeliveryDate": delivery_date.strftime("%Y-%m-%d"),
                "Carrier": self.rng.choice(CARRIERS),
                "ShipMode": self.rng.choice(SHIP_MODES),
                "ShippingCost": shipping_cost,
                "TrackingNumber": self.fake.bothify("1Z###########"),
            })

        shipping_df = pd.DataFrame(rows)
        shipping_df.to_csv(self.output_dir / "shipping.csv", index=False, encoding="utf-8")
        print(f"        → {len(shipping_df)} rows")


    def _gen_inventory(self) -> None:
        """Generate inventory.csv — monthly snapshots per product per store."""
        print("[12/12] Generating inventory.csv ...")
        # Generate quarterly snapshots to keep volume manageable
        snapshot_dates = pd.date_range(
            start=self.profile.date_start,
            end=self.profile.date_end,
            freq="QS",  # Quarter start
        )
        # Sample a subset of store-product combinations
        num_store_product_pairs = min(
            self.profile.num_stores * self.profile.num_products,
            200_000 if self.profile.name == "production" else 20_000,
        )
        store_ids = self.rng.integers(1, self.profile.num_stores + 1, size=num_store_product_pairs)
        product_ids = self.rng.integers(1, self.profile.num_products + 1, size=num_store_product_pairs)

        rows = []
        inv_id = 1
        for snap_date in snapshot_dates:
            for i in range(num_store_product_pairs):
                qty_on_hand = int(self.rng.integers(0, 500))
                reorder_point = int(self.rng.integers(10, 100))
                reorder_qty = int(self.rng.integers(50, 300))
                rows.append({
                    "InventoryID": inv_id,
                    "ProductID": int(product_ids[i]),
                    "StoreID": int(store_ids[i]),
                    "SnapshotDate": snap_date.strftime("%Y-%m-%d"),
                    "QuantityOnHand": qty_on_hand,
                    "ReorderPoint": reorder_point,
                    "ReorderQuantity": reorder_qty,
                })
                inv_id += 1

        inventory_df = pd.DataFrame(rows)
        inventory_df.to_csv(self.output_dir / "inventory.csv", index=False, encoding="utf-8")
        print(f"        → {len(inventory_df)} rows")


# =============================================================================
# CLI ENTRY POINT
# =============================================================================


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="ShopStar Retail - Synthetic Dataset Generator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Profiles:
  development  50,000 orders, ~200K details (< 60 seconds)
  production   500,000 orders, 2M details (several minutes)

Examples:
  python generate_dataset.py --profile development
  python generate_dataset.py --profile production --output /data/retail
        """,
    )
    parser.add_argument(
        "--profile",
        choices=list(PROFILES.keys()),
        default="development",
        help="Generation profile (default: development)",
    )
    parser.add_argument(
        "--output",
        type=str,
        default=None,
        help="Output directory (default: ../Dataset)",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    profile = PROFILES[args.profile]

    if args.output:
        output_dir = Path(args.output)
    else:
        output_dir = Path(__file__).resolve().parent.parent / "Dataset"

    generator = RetailDataGenerator(profile=profile, output_dir=output_dir)
    generator.generate_all()


if __name__ == "__main__":
    main()
