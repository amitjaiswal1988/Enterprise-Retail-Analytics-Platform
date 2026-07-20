"""
Enterprise Retail Analytics Platform - Data Quality Tests
==========================================================

Validates the generated dataset against expected schema, volumes,
referential integrity, and documented defect rates.

Run:
    python -m pytest tests/test_data_quality.py -v

Prerequisites:
    Generate the development dataset first:
        cd Python && python generate_dataset.py --profile development
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import pytest

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

DATASET_DIR = Path(__file__).resolve().parent.parent / "Dataset"
GENERATOR_SCRIPT = Path(__file__).resolve().parent.parent / "Python" / "generate_dataset.py"


@pytest.fixture(scope="session", autouse=True)
def generate_dataset():
    """Generate development dataset once before all tests run."""
    if not (DATASET_DIR / "orders.csv").exists():
        subprocess.run(
            [sys.executable, str(GENERATOR_SCRIPT), "--profile", "development"],
            check=True,
        )
    yield


@pytest.fixture(scope="session")
def regions():
    return pd.read_csv(DATASET_DIR / "regions.csv", encoding="utf-8")


@pytest.fixture(scope="session")
def categories():
    return pd.read_csv(DATASET_DIR / "categories.csv", encoding="utf-8")


@pytest.fixture(scope="session")
def suppliers():
    return pd.read_csv(DATASET_DIR / "suppliers.csv", encoding="utf-8")


@pytest.fixture(scope="session")
def products():
    return pd.read_csv(DATASET_DIR / "products.csv", encoding="utf-8")


@pytest.fixture(scope="session")
def stores():
    return pd.read_csv(DATASET_DIR / "stores.csv", encoding="utf-8")


@pytest.fixture(scope="session")
def employees():
    return pd.read_csv(DATASET_DIR / "employees.csv", encoding="utf-8")


@pytest.fixture(scope="session")
def customers():
    return pd.read_csv(DATASET_DIR / "customers.csv", encoding="utf-8")


@pytest.fixture(scope="session")
def orders():
    return pd.read_csv(DATASET_DIR / "orders.csv", encoding="utf-8")


@pytest.fixture(scope="session")
def order_details():
    return pd.read_csv(DATASET_DIR / "order_details.csv", encoding="utf-8")


@pytest.fixture(scope="session")
def returns():
    return pd.read_csv(DATASET_DIR / "returns.csv", encoding="utf-8")


@pytest.fixture(scope="session")
def shipping():
    return pd.read_csv(DATASET_DIR / "shipping.csv", encoding="utf-8")


@pytest.fixture(scope="session")
def inventory():
    return pd.read_csv(DATASET_DIR / "inventory.csv", encoding="utf-8")


# ---------------------------------------------------------------------------
# Test: All 12 files exist
# ---------------------------------------------------------------------------

class TestFileExistence:
    """Verify all expected output files are generated."""

    EXPECTED_FILES = [
        "regions.csv", "categories.csv", "suppliers.csv", "products.csv",
        "stores.csv", "employees.csv", "customers.csv", "orders.csv",
        "order_details.csv", "returns.csv", "shipping.csv", "inventory.csv",
    ]

    @pytest.mark.parametrize("filename", EXPECTED_FILES)
    def test_file_exists(self, filename):
        filepath = DATASET_DIR / filename
        assert filepath.exists(), f"Missing file: {filepath}"

    @pytest.mark.parametrize("filename", EXPECTED_FILES)
    def test_file_not_empty(self, filename):
        filepath = DATASET_DIR / filename
        assert filepath.stat().st_size > 0, f"Empty file: {filepath}"


# ---------------------------------------------------------------------------
# Test: Schema compliance (column names)
# ---------------------------------------------------------------------------

class TestSchema:
    """Verify each file has the expected columns."""

    def test_regions_columns(self, regions):
        assert set(regions.columns) == {"RegionID", "RegionName"}

    def test_categories_columns(self, categories):
        assert set(categories.columns) == {
            "CategoryID", "CategoryName", "SubCategoryName", "Department"
        }

    def test_suppliers_columns(self, suppliers):
        assert set(suppliers.columns) == {
            "SupplierID", "SupplierName", "Country",
            "LeadTimeDays", "Rating", "ContactEmail"
        }

    def test_products_columns(self, products):
        assert set(products.columns) == {
            "ProductID", "ProductName", "CategoryID", "Category",
            "SubCategory", "Brand", "UnitCost", "UnitPrice", "SupplierID"
        }

    def test_stores_columns(self, stores):
        assert set(stores.columns) == {
            "StoreID", "StoreName", "City", "State",
            "Region", "StoreType", "OpenDate", "SquareFootage"
        }

    def test_employees_columns(self, employees):
        assert set(employees.columns) == {
            "EmployeeID", "FirstName", "LastName", "Department",
            "Role", "StoreID", "HireDate", "Salary", "ManagerID"
        }

    def test_customers_columns(self, customers):
        assert set(customers.columns) == {
            "CustomerID", "FirstName", "LastName", "Email",
            "Segment", "JoinDate", "City", "State", "Region"
        }

    def test_orders_columns(self, orders):
        assert set(orders.columns) == {
            "OrderID", "CustomerID", "OrderDate",
            "StoreID", "EmployeeID", "Channel", "Status"
        }

    def test_order_details_columns(self, order_details):
        assert set(order_details.columns) == {
            "OrderDetailID", "OrderID", "ProductID",
            "Quantity", "UnitPrice", "Discount", "LineTotal"
        }

    def test_returns_columns(self, returns):
        assert set(returns.columns) == {
            "ReturnID", "OrderDetailID", "ReturnDate",
            "Reason", "RefundAmount", "Condition"
        }

    def test_shipping_columns(self, shipping):
        assert set(shipping.columns) == {
            "ShippingID", "OrderID", "ShipDate", "DeliveryDate",
            "Carrier", "ShipMode", "ShippingCost", "TrackingNumber"
        }

    def test_inventory_columns(self, inventory):
        assert set(inventory.columns) == {
            "InventoryID", "ProductID", "StoreID",
            "SnapshotDate", "QuantityOnHand", "ReorderPoint", "ReorderQuantity"
        }


# ---------------------------------------------------------------------------
# Test: Row counts within expected ranges (development profile)
# ---------------------------------------------------------------------------

class TestVolumes:
    """Verify row counts match development profile expectations."""

    def test_regions_count(self, regions):
        assert len(regions) == 4

    def test_categories_count(self, categories):
        assert 20 <= len(categories) <= 50

    def test_suppliers_count(self, suppliers):
        assert len(suppliers) == 100

    def test_products_count(self, products):
        assert len(products) == 2000

    def test_stores_count(self, stores):
        assert len(stores) == 50

    def test_employees_count(self, employees):
        assert len(employees) == 1000

    def test_customers_count(self, customers):
        assert len(customers) == 20000

    def test_orders_count(self, orders):
        # 50,000 base + ~250 duplicates
        assert 50_000 <= len(orders) <= 51_000

    def test_order_details_count(self, order_details):
        # ~4 lines per order * ~50,250 orders
        assert 150_000 <= len(order_details) <= 300_000

    def test_returns_count(self, returns):
        assert 5_000 <= len(returns) <= 15_000

    def test_shipping_count(self, shipping):
        assert 15_000 <= len(shipping) <= 35_000

    def test_inventory_count(self, inventory):
        assert 100_000 <= len(inventory) <= 600_000


# ---------------------------------------------------------------------------
# Test: Referential integrity (valid FK references, excluding known defects)
# ---------------------------------------------------------------------------

class TestReferentialIntegrity:
    """Verify FK relationships hold (accounting for documented defects)."""

    def test_products_reference_valid_suppliers(self, products, suppliers):
        valid_ids = set(suppliers["SupplierID"])
        orphans = products[~products["SupplierID"].isin(valid_ids)]
        assert len(orphans) == 0, f"Products with invalid SupplierID: {len(orphans)}"

    def test_products_reference_valid_categories(self, products, categories):
        valid_ids = set(categories["CategoryID"])
        orphans = products[~products["CategoryID"].isin(valid_ids)]
        assert len(orphans) == 0, f"Products with invalid CategoryID: {len(orphans)}"

    def test_orders_reference_valid_customers(self, orders, customers):
        valid_ids = set(customers["CustomerID"])
        orphans = orders[~orders["CustomerID"].isin(valid_ids)]
        assert len(orphans) == 0, f"Orders with invalid CustomerID: {len(orphans)}"

    def test_order_details_reference_valid_orders(self, order_details, orders):
        valid_ids = set(orders["OrderID"])
        orphans = order_details[~order_details["OrderID"].isin(valid_ids)]
        assert len(orphans) == 0, f"OrderDetails with invalid OrderID: {len(orphans)}"

    def test_returns_reference_valid_order_details(self, returns, order_details):
        valid_ids = set(order_details["OrderDetailID"])
        orphans = returns[~returns["OrderDetailID"].isin(valid_ids)]
        assert len(orphans) == 0, f"Returns with invalid OrderDetailID: {len(orphans)}"

    def test_shipping_reference_valid_orders(self, shipping, orders):
        valid_ids = set(orders["OrderID"])
        orphans = shipping[~shipping["OrderID"].isin(valid_ids)]
        assert len(orphans) == 0, f"Shipping with invalid OrderID: {len(orphans)}"


# ---------------------------------------------------------------------------
# Test: Documented defects are present at expected rates
# ---------------------------------------------------------------------------

class TestDefectInjection:
    """Verify intentional defects exist at documented rates (within tolerance)."""

    def test_def01_null_emails(self, customers):
        """DEF-01: ~5% of customer emails should be NULL."""
        null_rate = customers["Email"].isna().mean()
        assert 0.03 <= null_rate <= 0.08, (
            f"NULL email rate {null_rate:.3f} outside expected range [0.03, 0.08]"
        )

    def test_def02_duplicate_orders(self, orders):
        """DEF-02: ~0.5% duplicate rows should exist."""
        total = len(orders)
        unique = orders.drop_duplicates().shape[0]
        dupe_rate = (total - unique) / total
        assert 0.002 <= dupe_rate <= 0.01, (
            f"Duplicate rate {dupe_rate:.4f} outside expected range [0.002, 0.01]"
        )

    def test_def03_future_dates(self, orders):
        """DEF-03: ~0.1% of order dates should be in the future (>2025-12-31)."""
        dates = pd.to_datetime(orders["OrderDate"], errors="coerce")
        future_count = (dates > pd.Timestamp("2025-12-31")).sum()
        future_rate = future_count / len(orders)
        assert future_count > 0, "No future date defects found"
        assert future_rate <= 0.005, (
            f"Future date rate {future_rate:.4f} unexpectedly high"
        )

    def test_def04_orphan_products(self, order_details, products):
        """DEF-04: ~0.2% of order details reference non-existent products."""
        valid_ids = set(products["ProductID"])
        orphan_count = (~order_details["ProductID"].isin(valid_ids)).sum()
        orphan_rate = orphan_count / len(order_details)
        assert orphan_count > 0, "No orphan product defects found"
        assert 0.001 <= orphan_rate <= 0.005, (
            f"Orphan product rate {orphan_rate:.4f} outside expected range"
        )

    def test_def05_inconsistent_casing(self, categories):
        """DEF-05: Some category names have non-standard casing."""
        canonical = {"Electronics", "Home & Kitchen", "Office Supplies",
                     "Furniture", "Technology Accessories"}
        non_canonical = categories[~categories["CategoryName"].isin(canonical)]
        assert len(non_canonical) > 0, "No casing defects found in categories"

    def test_def06_negative_quantities(self, order_details):
        """DEF-06: ~0.1% of quantities should be negative."""
        neg_count = (order_details["Quantity"] < 0).sum()
        neg_rate = neg_count / len(order_details)
        assert neg_count > 0, "No negative quantity defects found"
        assert neg_rate <= 0.005, (
            f"Negative quantity rate {neg_rate:.4f} unexpectedly high"
        )


# ---------------------------------------------------------------------------
# Test: Business rules are correctly embedded
# ---------------------------------------------------------------------------

class TestBusinessRules:
    """Verify business logic is reflected in the generated data."""

    def test_channel_distribution(self, orders):
        """Channel split should approximate 60% Store / 40% E-commerce."""
        store_rate = (orders["Channel"] == "Store").mean()
        assert 0.50 <= store_rate <= 0.70, (
            f"Store channel rate {store_rate:.2f} outside expected [0.50, 0.70]"
        )

    def test_ecommerce_orders_have_null_store(self, orders):
        """E-commerce orders should have NULL StoreID."""
        ecom = orders[orders["Channel"] == "E-commerce"]
        null_store_rate = ecom["StoreID"].isna().mean()
        assert null_store_rate > 0.99, (
            f"E-commerce NULL StoreID rate {null_store_rate:.3f} should be ~1.0"
        )

    def test_store_orders_have_store_and_employee(self, orders):
        """Store orders should have non-NULL StoreID and EmployeeID."""
        store_orders = orders[orders["Channel"] == "Store"]
        has_store = store_orders["StoreID"].notna().mean()
        has_emp = store_orders["EmployeeID"].notna().mean()
        assert has_store > 0.99
        assert has_emp > 0.99

    def test_order_status_distribution(self, orders):
        """Order status should be predominantly Completed (~85%)."""
        completed_rate = (orders["Status"] == "Completed").mean()
        assert 0.75 <= completed_rate <= 0.92

    def test_product_price_exceeds_cost(self, products):
        """UnitPrice should be > UnitCost for all products (positive margin)."""
        invalid = products[products["UnitPrice"] <= products["UnitCost"]]
        assert len(invalid) == 0, (
            f"{len(invalid)} products have price <= cost"
        )

    def test_return_rate_within_bounds(self, returns, order_details):
        """Return rate should approximate 5% of completed order details."""
        return_rate = len(returns) / len(order_details)
        assert 0.02 <= return_rate <= 0.08, (
            f"Return rate {return_rate:.3f} outside expected [0.02, 0.08]"
        )

    def test_regions_are_four_us_regions(self, regions):
        """Should have exactly East, West, North, South."""
        expected = {"East", "West", "North", "South"}
        assert set(regions["RegionName"]) == expected


# ---------------------------------------------------------------------------
# Test: Deterministic reproducibility
# ---------------------------------------------------------------------------

class TestReproducibility:
    """Verify that re-running the generator produces identical output."""

    def test_orders_deterministic(self, tmp_path):
        """Generate twice to different dirs; orders.csv must match."""
        dir1 = tmp_path / "run1"
        dir2 = tmp_path / "run2"

        subprocess.run(
            [sys.executable, str(GENERATOR_SCRIPT), "--profile", "development",
             "--output", str(dir1)],
            check=True,
        )
        subprocess.run(
            [sys.executable, str(GENERATOR_SCRIPT), "--profile", "development",
             "--output", str(dir2)],
            check=True,
        )

        df1 = pd.read_csv(dir1 / "orders.csv")
        df2 = pd.read_csv(dir2 / "orders.csv")
        pd.testing.assert_frame_equal(df1, df2)
