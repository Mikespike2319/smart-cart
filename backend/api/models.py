from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    full_name = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)
    preferences = Column(JSON)

    shopping_lists = relationship("ShoppingList", back_populates="user")
    favorite_stores = relationship("Store", secondary="user_favorite_stores")

class Store(Base):
    __tablename__ = "stores"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    location = Column(String)
    latitude = Column(Float)
    longitude = Column(Float)
    website = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)

    products = relationship("Product", back_populates="store")
    users = relationship("User", secondary="user_favorite_stores")

class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(String)
    brand = Column(String, index=True)
    category = Column(String, index=True)
    barcode = Column(String, unique=True, index=True)
    image_url = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    store_id = Column(Integer, ForeignKey("stores.id"))

    store = relationship("Store", back_populates="products")
    prices = relationship("Price", back_populates="product")

class Price(Base):
    __tablename__ = "prices"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"))
    price = Column(Float)
    currency = Column(String, default="USD")
    timestamp = Column(DateTime, default=datetime.utcnow)
    is_sale = Column(Boolean, default=False)
    sale_end_date = Column(DateTime, nullable=True)

    product = relationship("Product", back_populates="prices")

class ShoppingList(Base):
    __tablename__ = "shopping_lists"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    name = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)

    user = relationship("User", back_populates="shopping_lists")
    items = relationship("ShoppingListItem", back_populates="shopping_list")

class ShoppingListItem(Base):
    __tablename__ = "shopping_list_items"

    id = Column(Integer, primary_key=True, index=True)
    shopping_list_id = Column(Integer, ForeignKey("shopping_lists.id"))
    product_id = Column(Integer, ForeignKey("products.id"))
    quantity = Column(Integer, default=1)
    is_purchased = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    shopping_list = relationship("ShoppingList", back_populates="items")
    product = relationship("Product")

# Association table for user favorite stores
class UserFavoriteStore(Base):
    __tablename__ = "user_favorite_stores"

    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    store_id = Column(Integer, ForeignKey("stores.id"), primary_key=True)
    created_at = Column(DateTime, default=datetime.utcnow) 