import strawberry
from typing import List, Optional
from datetime import datetime

@strawberry.type
class User:
    id: int
    email: str
    full_name: str
    created_at: datetime
    is_active: bool
    preferences: Optional[dict]

@strawberry.type
class Store:
    id: int
    name: str
    location: str
    latitude: float
    longitude: float
    website: str
    created_at: datetime
    is_active: bool

@strawberry.type
class Product:
    id: int
    name: str
    description: str
    brand: str
    category: str
    barcode: str
    image_url: str
    created_at: datetime
    store_id: int

@strawberry.type
class Price:
    id: int
    product_id: int
    price: float
    currency: str
    timestamp: datetime
    is_sale: bool
    sale_end_date: Optional[datetime]

@strawberry.type
class ShoppingList:
    id: int
    user_id: int
    name: str
    created_at: datetime
    is_active: bool

@strawberry.type
class ShoppingListItem:
    id: int
    shopping_list_id: int
    product_id: int
    quantity: int
    is_purchased: bool
    created_at: datetime

@strawberry.input
class UserInput:
    email: str
    password: str
    full_name: str
    preferences: Optional[dict]

@strawberry.input
class ProductInput:
    name: str
    description: str
    brand: str
    category: str
    barcode: str
    image_url: str
    store_id: int

@strawberry.input
class PriceInput:
    product_id: int
    price: float
    currency: str
    is_sale: bool
    sale_end_date: Optional[datetime]

@strawberry.type
class Query:
    @strawberry.field
    def user(self, id: int) -> Optional[User]:
        # TODO: Implement user query
        pass

    @strawberry.field
    def users(self) -> List[User]:
        # TODO: Implement users query
        pass

    @strawberry.field
    def store(self, id: int) -> Optional[Store]:
        # TODO: Implement store query
        pass

    @strawberry.field
    def stores(self) -> List[Store]:
        # TODO: Implement stores query
        pass

    @strawberry.field
    def product(self, id: int) -> Optional[Product]:
        # TODO: Implement product query
        pass

    @strawberry.field
    def products(self, category: Optional[str] = None) -> List[Product]:
        # TODO: Implement products query
        pass

    @strawberry.field
    def shopping_list(self, id: int) -> Optional[ShoppingList]:
        # TODO: Implement shopping list query
        pass

    @strawberry.field
    def shopping_lists(self, user_id: int) -> List[ShoppingList]:
        # TODO: Implement shopping lists query
        pass

@strawberry.type
class Mutation:
    @strawberry.mutation
    def create_user(self, user: UserInput) -> User:
        # TODO: Implement user creation
        pass

    @strawberry.mutation
    def update_user(self, id: int, user: UserInput) -> User:
        # TODO: Implement user update
        pass

    @strawberry.mutation
    def create_product(self, product: ProductInput) -> Product:
        # TODO: Implement product creation
        pass

    @strawberry.mutation
    def update_price(self, price: PriceInput) -> Price:
        # TODO: Implement price update
        pass

    @strawberry.mutation
    def create_shopping_list(self, user_id: int, name: str) -> ShoppingList:
        # TODO: Implement shopping list creation
        pass

    @strawberry.mutation
    def add_to_shopping_list(self, shopping_list_id: int, product_id: int, quantity: int) -> ShoppingListItem:
        # TODO: Implement add to shopping list
        pass

schema = strawberry.Schema(query=Query, mutation=Mutation) 