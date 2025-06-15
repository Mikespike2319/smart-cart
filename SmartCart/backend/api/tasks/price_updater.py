import asyncio
import logging
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from ..database import SessionLocal
from ..services.store_integration import StoreIntegrationService
from ..models import Product, Price

logger = logging.getLogger(__name__)

class PriceUpdater:
    def __init__(self, update_interval: int = 3600):  # Default: 1 hour
        self.update_interval = update_interval
        self.is_running = False

    async def start(self):
        """Start the price update task."""
        self.is_running = True
        while self.is_running:
            try:
                await self.update_prices()
            except Exception as e:
                logger.error(f"Error updating prices: {str(e)}")
            await asyncio.sleep(self.update_interval)

    async def stop(self):
        """Stop the price update task."""
        self.is_running = False

    async def update_prices(self):
        """Update prices for all products."""
        db = SessionLocal()
        try:
            async with StoreIntegrationService(db) as store_service:
                # Get products that need price updates
                products = self._get_products_to_update(db)
                
                # Update prices for each product
                for product in products:
                    try:
                        await store_service.update_prices()
                        self._update_last_checked(db, product)
                    except Exception as e:
                        logger.error(f"Error updating prices for product {product.id}: {str(e)}")
        finally:
            db.close()

    def _get_products_to_update(self, db: Session) -> List[Product]:
        """Get products that need price updates."""
        # Get products that haven't been checked in the last hour
        one_hour_ago = datetime.utcnow() - timedelta(hours=1)
        return (
            db.query(Product)
            .filter(Product.last_price_check < one_hour_ago)
            .all()
        )

    def _update_last_checked(self, db: Session, product: Product):
        """Update the last price check timestamp for a product."""
        product.last_price_check = datetime.utcnow()
        db.commit()

# Create a singleton instance
price_updater = PriceUpdater()

# Function to start the price updater
async def start_price_updater():
    """Start the price updater task."""
    await price_updater.start()

# Function to stop the price updater
async def stop_price_updater():
    """Stop the price updater task."""
    await price_updater.stop() 