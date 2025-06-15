import os
import json
import aiohttp
import asyncio
from typing import List, Dict, Optional
from datetime import datetime
from sqlalchemy.orm import Session

from api.models import Store, Product, Price
from api.database import get_db

class StoreAPIError(Exception):
    pass

class StoreAPIClient:
    def __init__(self, store: Store):
        self.store = store
        self.api_config = store.api_config
        self.base_url = self.api_config.get("base_url")
        self.api_key = self.api_config.get("api_key")
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

    async def search_products(self, query: str) -> List[Dict]:
        """Search for products in the store's catalog."""
        if self.store.name == "Walmart":
            return await self._walmart_search(query)
        elif self.store.name == "Kroger":
            return await self._kroger_search(query)
        elif self.store.name == "Target":
            return await self._target_search(query)
        else:
            raise StoreAPIError(f"Unsupported store: {self.store.name}")

    async def get_product_price(self, product_id: str) -> Dict:
        """Get current price for a specific product."""
        if self.store.name == "Walmart":
            return await self._walmart_get_price(product_id)
        elif self.store.name == "Kroger":
            return await self._kroger_get_price(product_id)
        elif self.store.name == "Target":
            return await self._target_get_price(product_id)
        else:
            raise StoreAPIError(f"Unsupported store: {self.store.name}")

    async def _walmart_search(self, query: str) -> List[Dict]:
        """Search Walmart's product catalog."""
        async with aiohttp.ClientSession() as session:
            url = f"{self.base_url}/items/search"
            params = {
                "query": query,
                "limit": 20
            }
            async with session.get(url, headers=self.headers, params=params) as response:
                if response.status != 200:
                    raise StoreAPIError(f"Walmart API error: {response.status}")
                data = await response.json()
                return self._parse_walmart_products(data)

    async def _kroger_search(self, query: str) -> List[Dict]:
        """Search Kroger's product catalog."""
        async with aiohttp.ClientSession() as session:
            url = f"{self.base_url}/products/search"
            params = {
                "term": query,
                "limit": 20
            }
            async with session.get(url, headers=self.headers, params=params) as response:
                if response.status != 200:
                    raise StoreAPIError(f"Kroger API error: {response.status}")
                data = await response.json()
                return self._parse_kroger_products(data)

    async def _target_search(self, query: str) -> List[Dict]:
        """Search Target's product catalog."""
        async with aiohttp.ClientSession() as session:
            url = f"{self.base_url}/products/search"
            params = {
                "searchTerm": query,
                "limit": 20
            }
            async with session.get(url, headers=self.headers, params=params) as response:
                if response.status != 200:
                    raise StoreAPIError(f"Target API error: {response.status}")
                data = await response.json()
                return self._parse_target_products(data)

    async def _walmart_get_price(self, product_id: str) -> Dict:
        """Get price from Walmart."""
        async with aiohttp.ClientSession() as session:
            url = f"{self.base_url}/items/{product_id}/price"
            async with session.get(url, headers=self.headers) as response:
                if response.status != 200:
                    raise StoreAPIError(f"Walmart API error: {response.status}")
                data = await response.json()
                return self._parse_walmart_price(data)

    async def _kroger_get_price(self, product_id: str) -> Dict:
        """Get price from Kroger."""
        async with aiohttp.ClientSession() as session:
            url = f"{self.base_url}/products/{product_id}/price"
            async with session.get(url, headers=self.headers) as response:
                if response.status != 200:
                    raise StoreAPIError(f"Kroger API error: {response.status}")
                data = await response.json()
                return self._parse_kroger_price(data)

    async def _target_get_price(self, product_id: str) -> Dict:
        """Get price from Target."""
        async with aiohttp.ClientSession() as session:
            url = f"{self.base_url}/products/{product_id}/price"
            async with session.get(url, headers=self.headers) as response:
                if response.status != 200:
                    raise StoreAPIError(f"Target API error: {response.status}")
                data = await response.json()
                return self._parse_target_price(data)

    def _parse_walmart_products(self, data: Dict) -> List[Dict]:
        """Parse Walmart product search results."""
        products = []
        for item in data.get("items", []):
            products.append({
                "name": item.get("name"),
                "brand": item.get("brand"),
                "category": item.get("category"),
                "description": item.get("description"),
                "image_url": item.get("imageUrl"),
                "barcode": item.get("upc"),
                "store_product_id": item.get("itemId"),
                "price": item.get("price", {}).get("amount"),
                "currency": item.get("price", {}).get("currency"),
                "is_sale": item.get("price", {}).get("isSale", False),
                "sale_end_date": item.get("price", {}).get("saleEndDate")
            })
        return products

    def _parse_kroger_products(self, data: Dict) -> List[Dict]:
        """Parse Kroger product search results."""
        products = []
        for item in data.get("products", []):
            products.append({
                "name": item.get("description"),
                "brand": item.get("brand"),
                "category": item.get("category"),
                "description": item.get("longDescription"),
                "image_url": item.get("imageUrl"),
                "barcode": item.get("upc"),
                "store_product_id": item.get("productId"),
                "price": item.get("price", {}).get("regular"),
                "currency": "USD",
                "is_sale": item.get("price", {}).get("sale") is not None,
                "sale_end_date": item.get("price", {}).get("saleEndDate")
            })
        return products

    def _parse_target_products(self, data: Dict) -> List[Dict]:
        """Parse Target product search results."""
        products = []
        for item in data.get("products", []):
            products.append({
                "name": item.get("title"),
                "brand": item.get("brand"),
                "category": item.get("category"),
                "description": item.get("description"),
                "image_url": item.get("imageUrl"),
                "barcode": item.get("tcin"),
                "store_product_id": item.get("productId"),
                "price": item.get("price", {}).get("current"),
                "currency": "USD",
                "is_sale": item.get("price", {}).get("isOnSale", False),
                "sale_end_date": item.get("price", {}).get("saleEndDate")
            })
        return products

    def _parse_walmart_price(self, data: Dict) -> Dict:
        """Parse Walmart price data."""
        return {
            "price": data.get("price", {}).get("amount"),
            "currency": data.get("price", {}).get("currency"),
            "is_sale": data.get("price", {}).get("isSale", False),
            "sale_end_date": data.get("price", {}).get("saleEndDate")
        }

    def _parse_kroger_price(self, data: Dict) -> Dict:
        """Parse Kroger price data."""
        return {
            "price": data.get("price", {}).get("regular"),
            "currency": "USD",
            "is_sale": data.get("price", {}).get("sale") is not None,
            "sale_end_date": data.get("price", {}).get("saleEndDate")
        }

    def _parse_target_price(self, data: Dict) -> Dict:
        """Parse Target price data."""
        return {
            "price": data.get("price", {}).get("current"),
            "currency": "USD",
            "is_sale": data.get("price", {}).get("isOnSale", False),
            "sale_end_date": data.get("price", {}).get("saleEndDate")
        }

class StoreAPIService:
    def __init__(self, db: Session):
        self.db = db
        self.stores = self._load_stores()

    def _load_stores(self) -> List[Store]:
        """Load all active stores from the database."""
        return self.db.query(Store).filter(Store.is_active == True).all()

    async def search_all_stores(self, query: str) -> List[Dict]:
        """Search for products across all stores."""
        tasks = []
        for store in self.stores:
            client = StoreAPIClient(store)
            tasks.append(client.search_products(query))
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        products = []
        for store, result in zip(self.stores, results):
            if isinstance(result, Exception):
                print(f"Error searching {store.name}: {str(result)}")
                continue
            
            for product in result:
                product["store_name"] = store.name
                product["store_id"] = store.id
                products.append(product)
        
        return products

    async def get_all_prices(self, product_id: str) -> List[Dict]:
        """Get current prices for a product from all stores."""
        tasks = []
        for store in self.stores:
            client = StoreAPIClient(store)
            tasks.append(client.get_product_price(product_id))
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        prices = []
        for store, result in zip(self.stores, results):
            if isinstance(result, Exception):
                print(f"Error getting price from {store.name}: {str(result)}")
                continue
            
            price = result
            price["store_name"] = store.name
            price["store_id"] = store.id
            prices.append(price)
        
        return prices

    async def update_product_prices(self, product: Product) -> None:
        """Update prices for a product from all stores."""
        prices = await self.get_all_prices(product.store_product_id)
        
        for price_data in prices:
            price = Price(
                product_id=product.id,
                store_id=price_data["store_id"],
                price=price_data["price"],
                currency=price_data["currency"],
                is_sale=price_data["is_sale"],
                sale_end_date=price_data["sale_end_date"],
                timestamp=datetime.utcnow()
            )
            self.db.add(price)
        
        product.last_price_check = datetime.utcnow()
        self.db.commit() 