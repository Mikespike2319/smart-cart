import os
import sys
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from dotenv import load_dotenv

# Add the parent directory to the Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from api.database import SessionLocal
from api.models import User, Store, Product, Price, ShoppingList, ShoppingListItem, PriceAlert
from api.core.security import get_password_hash

def init_db(db: Session) -> None:
    # Create sample stores
    stores = [
        Store(
            name="Walmart",
            api_config={
                "api_key": os.getenv("WALMART_API_KEY"),
                "base_url": "https://api.walmart.com/v3"
            },
            is_active=True,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        ),
        Store(
            name="Kroger",
            api_config={
                "api_key": os.getenv("KROGER_API_KEY"),
                "base_url": "https://api.kroger.com/v1"
            },
            is_active=True,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        ),
        Store(
            name="Target",
            api_config={
                "api_key": os.getenv("TARGET_API_KEY"),
                "base_url": "https://api.target.com/v1"
            },
            is_active=True,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
    ]
    db.add_all(stores)
    db.commit()

    # Create sample user
    user = User(
        email="test@example.com",
        hashed_password=get_password_hash("password123"),
        full_name="Test User",
        is_active=True,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    db.add(user)
    db.commit()

    # Create sample products
    products = [
        Product(
            name="Organic Bananas",
            brand="Dole",
            category="Produce",
            description="Organic bananas, bunch of 6",
            image_url="https://example.com/bananas.jpg",
            barcode="123456789012",
            store_product_id="WAL123",
            store_id=stores[0].id,
            last_price_check=datetime.utcnow(),
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        ),
        Product(
            name="Whole Milk",
            brand="Horizon",
            category="Dairy",
            description="Organic whole milk, 1 gallon",
            image_url="https://example.com/milk.jpg",
            barcode="234567890123",
            store_product_id="KRO456",
            store_id=stores[1].id,
            last_price_check=datetime.utcnow(),
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        ),
        Product(
            name="Chicken Breast",
            brand="Tyson",
            category="Meat",
            description="Boneless chicken breast, 2 lbs",
            image_url="https://example.com/chicken.jpg",
            barcode="345678901234",
            store_product_id="TAR789",
            store_id=stores[2].id,
            last_price_check=datetime.utcnow(),
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
    ]
    db.add_all(products)
    db.commit()

    # Create sample prices
    prices = []
    for product in products:
        base_price = 4.99 if product.category == "Produce" else 5.99
        for i in range(7):  # Last 7 days of prices
            price_date = datetime.utcnow() - timedelta(days=i)
            prices.append(
                Price(
                    product_id=product.id,
                    store_id=product.store_id,
                    price=base_price - (0.5 if i % 3 == 0 else 0),  # Some days have sales
                    currency="USD",
                    is_sale=(i % 3 == 0),
                    sale_end_date=price_date + timedelta(days=2) if i % 3 == 0 else None,
                    timestamp=price_date
                )
            )
    db.add_all(prices)
    db.commit()

    # Create sample shopping list
    shopping_list = ShoppingList(
        user_id=user.id,
        name="Weekly Groceries",
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    db.add(shopping_list)
    db.commit()

    # Add items to shopping list
    shopping_list_items = [
        ShoppingListItem(
            shopping_list_id=shopping_list.id,
            product_id=products[0].id,
            quantity=2,
            is_checked=False,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        ),
        ShoppingListItem(
            shopping_list_id=shopping_list.id,
            product_id=products[1].id,
            quantity=1,
            is_checked=False,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
    ]
    db.add_all(shopping_list_items)
    db.commit()

    # Create sample price alerts
    price_alerts = [
        PriceAlert(
            user_id=user.id,
            product_id=products[0].id,
            target_price=3.99,
            is_active=True,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        ),
        PriceAlert(
            user_id=user.id,
            product_id=products[2].id,
            target_price=4.99,
            is_active=True,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
    ]
    db.add_all(price_alerts)
    db.commit()

def main() -> None:
    load_dotenv()
    db = SessionLocal()
    try:
        init_db(db)
    finally:
        db.close()

if __name__ == "__main__":
    main() 