import asyncio
import aiohttp
from bs4 import BeautifulSoup
from typing import List, Dict, Optional
from datetime import datetime
import logging
from sqlalchemy.orm import Session

from api.models import Product, Price, Store

logger = logging.getLogger(__name__)

class WebScraper:
    def __init__(self, db: Session):
        self.db = db
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }

    async def scrape_product_prices(self, product: Product) -> List[Dict]:
        """Scrape prices for a product from various sources."""
        tasks = []
        
        # Add scraping tasks for different sources
        tasks.append(self._scrape_amazon(product))
        tasks.append(self._scrape_instacart(product))
        tasks.append(self._scrape_peapod(product))
        
        # Run all scraping tasks concurrently
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Process results
        prices = []
        for result in results:
            if isinstance(result, Exception):
                logger.error(f"Scraping error: {str(result)}")
                continue
            if result:
                prices.extend(result)
        
        return prices

    async def _scrape_amazon(self, product: Product) -> List[Dict]:
        """Scrape prices from Amazon."""
        try:
            search_url = f"https://www.amazon.com/s?k={product.name.replace(' ', '+')}"
            async with aiohttp.ClientSession() as session:
                async with session.get(search_url, headers=self.headers) as response:
                    if response.status != 200:
                        return []
                    
                    html = await response.text()
                    soup = BeautifulSoup(html, 'html.parser')
                    
                    prices = []
                    for item in soup.select('.s-result-item'):
                        price_elem = item.select_one('.a-price .a-offscreen')
                        if not price_elem:
                            continue
                        
                        price_text = price_elem.text.strip()
                        if not price_text:
                            continue
                        
                        try:
                            price = float(price_text.replace('$', '').replace(',', ''))
                            prices.append({
                                'store_name': 'Amazon',
                                'price': price,
                                'currency': 'USD',
                                'is_sale': False,
                                'timestamp': datetime.utcnow()
                            })
                        except ValueError:
                            continue
                    
                    return prices
        except Exception as e:
            logger.error(f"Amazon scraping error: {str(e)}")
            return []

    async def _scrape_instacart(self, product: Product) -> List[Dict]:
        """Scrape prices from Instacart."""
        try:
            search_url = f"https://www.instacart.com/search/{product.name.replace(' ', '%20')}"
            async with aiohttp.ClientSession() as session:
                async with session.get(search_url, headers=self.headers) as response:
                    if response.status != 200:
                        return []
                    
                    html = await response.text()
                    soup = BeautifulSoup(html, 'html.parser')
                    
                    prices = []
                    for item in soup.select('.product-card'):
                        price_elem = item.select_one('.price')
                        if not price_elem:
                            continue
                        
                        price_text = price_elem.text.strip()
                        if not price_text:
                            continue
                        
                        try:
                            price = float(price_text.replace('$', '').replace(',', ''))
                            prices.append({
                                'store_name': 'Instacart',
                                'price': price,
                                'currency': 'USD',
                                'is_sale': False,
                                'timestamp': datetime.utcnow()
                            })
                        except ValueError:
                            continue
                    
                    return prices
        except Exception as e:
            logger.error(f"Instacart scraping error: {str(e)}")
            return []

    async def _scrape_peapod(self, product: Product) -> List[Dict]:
        """Scrape prices from Peapod."""
        try:
            search_url = f"https://www.peapod.com/search/{product.name.replace(' ', '%20')}"
            async with aiohttp.ClientSession() as session:
                async with session.get(search_url, headers=self.headers) as response:
                    if response.status != 200:
                        return []
                    
                    html = await response.text()
                    soup = BeautifulSoup(html, 'html.parser')
                    
                    prices = []
                    for item in soup.select('.product-item'):
                        price_elem = item.select_one('.price')
                        if not price_elem:
                            continue
                        
                        price_text = price_elem.text.strip()
                        if not price_text:
                            continue
                        
                        try:
                            price = float(price_text.replace('$', '').replace(',', ''))
                            prices.append({
                                'store_name': 'Peapod',
                                'price': price,
                                'currency': 'USD',
                                'is_sale': False,
                                'timestamp': datetime.utcnow()
                            })
                        except ValueError:
                            continue
                    
                    return prices
        except Exception as e:
            logger.error(f"Peapod scraping error: {str(e)}")
            return []

class ScrapingService:
    def __init__(self, db: Session):
        self.db = db
        self.scraper = WebScraper(db)

    async def update_product_prices(self, product: Product) -> None:
        """Update product prices from web scraping."""
        # Get scraped prices
        scraped_prices = await self.scraper.scrape_product_prices(product)
        
        # Create store records for new stores if needed
        for price_data in scraped_prices:
            store = self.db.query(Store).filter(
                Store.name == price_data['store_name']
            ).first()
            
            if not store:
                store = Store(
                    name=price_data['store_name'],
                    api_config={},
                    is_active=True,
                    created_at=datetime.utcnow(),
                    updated_at=datetime.utcnow()
                )
                self.db.add(store)
                self.db.commit()
            
            # Create price record
            price = Price(
                product_id=product.id,
                store_id=store.id,
                price=price_data['price'],
                currency=price_data['currency'],
                is_sale=price_data['is_sale'],
                timestamp=price_data['timestamp']
            )
            self.db.add(price)
        
        # Update product's last price check
        product.last_price_check = datetime.utcnow()
        self.db.commit()

    async def update_all_products(self) -> None:
        """Update prices for all products."""
        products = self.db.query(Product).all()
        for product in products:
            try:
                await self.update_product_prices(product)
            except Exception as e:
                logger.error(f"Error updating prices for product {product.id}: {str(e)}")
                continue 