import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from typing import List, Dict, Optional
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
import joblib
from sqlalchemy.orm import Session
from sqlalchemy import func

from api.models import Product, Price, Store

class PricePredictor:
    def __init__(self, db: Session):
        self.db = db
        self.model = None
        self.scaler = StandardScaler()
        self.feature_columns = [
            'day_of_week',
            'month',
            'is_holiday',
            'days_until_holiday',
            'price_trend',
            'price_volatility',
            'store_price_diff'
        ]

    def _prepare_features(self, product: Product, days: int = 30) -> pd.DataFrame:
        """Prepare features for price prediction."""
        # Get historical prices
        prices = self.db.query(Price).filter(
            Price.product_id == product.id
        ).order_by(Price.timestamp).all()

        if not prices:
            return pd.DataFrame()

        # Convert to DataFrame
        df = pd.DataFrame([{
            'timestamp': p.timestamp,
            'price': p.price,
            'store_id': p.store_id,
            'is_sale': p.is_sale
        } for p in prices])

        # Add time-based features
        df['day_of_week'] = df['timestamp'].dt.dayofweek
        df['month'] = df['timestamp'].dt.month
        df['is_holiday'] = self._is_holiday(df['timestamp'])
        df['days_until_holiday'] = self._days_until_holiday(df['timestamp'])

        # Add price-based features
        df['price_trend'] = df['price'].rolling(window=7).mean()
        df['price_volatility'] = df['price'].rolling(window=7).std()

        # Add store price difference
        store_prices = df.groupby('store_id')['price'].mean()
        df['store_price_diff'] = df.apply(
            lambda x: x['price'] - store_prices[x['store_id']],
            axis=1
        )

        return df[self.feature_columns]

    def _is_holiday(self, dates: pd.Series) -> pd.Series:
        """Check if dates are holidays."""
        # Add major US holidays
        holidays = [
            '2024-01-01',  # New Year's Day
            '2024-01-15',  # Martin Luther King Jr. Day
            '2024-02-19',  # Presidents' Day
            '2024-05-27',  # Memorial Day
            '2024-07-04',  # Independence Day
            '2024-09-02',  # Labor Day
            '2024-10-14',  # Columbus Day
            '2024-11-11',  # Veterans Day
            '2024-11-28',  # Thanksgiving Day
            '2024-12-25',  # Christmas Day
        ]
        return dates.dt.date.astype(str).isin(holidays)

    def _days_until_holiday(self, dates: pd.Series) -> pd.Series:
        """Calculate days until next holiday."""
        holidays = pd.to_datetime([
            '2024-01-01', '2024-01-15', '2024-02-19', '2024-05-27',
            '2024-07-04', '2024-09-02', '2024-10-14', '2024-11-11',
            '2024-11-28', '2024-12-25'
        ])
        
        def days_to_next(date):
            next_holiday = holidays[holidays > date].min()
            if pd.isna(next_holiday):
                return 365  # Default to 1 year if no next holiday
            return (next_holiday - date).days

        return dates.apply(days_to_next)

    def train(self, product: Product) -> None:
        """Train the price prediction model for a product."""
        # Prepare features
        df = self._prepare_features(product)
        if df.empty:
            return

        # Get target prices
        prices = self.db.query(Price).filter(
            Price.product_id == product.id
        ).order_by(Price.timestamp).all()
        y = np.array([p.price for p in prices])

        # Scale features
        X = self.scaler.fit_transform(df)

        # Train model
        self.model = RandomForestRegressor(
            n_estimators=100,
            max_depth=10,
            random_state=42
        )
        self.model.fit(X, y)

    def predict(self, product: Product, days: int = 30) -> List[Dict]:
        """Predict prices for the next n days."""
        if not self.model:
            self.train(product)

        if not self.model:
            return []

        # Generate future dates
        last_date = self.db.query(func.max(Price.timestamp)).filter(
            Price.product_id == product.id
        ).scalar()
        if not last_date:
            return []

        future_dates = pd.date_range(
            start=last_date + timedelta(days=1),
            periods=days,
            freq='D'
        )

        # Prepare features for future dates
        future_df = pd.DataFrame({
            'timestamp': future_dates
        })
        future_df['day_of_week'] = future_df['timestamp'].dt.dayofweek
        future_df['month'] = future_df['timestamp'].dt.month
        future_df['is_holiday'] = self._is_holiday(future_df['timestamp'])
        future_df['days_until_holiday'] = self._days_until_holiday(future_df['timestamp'])

        # Use last known values for price-based features
        last_price = self.db.query(Price).filter(
            Price.product_id == product.id
        ).order_by(Price.timestamp.desc()).first()

        if last_price:
            future_df['price_trend'] = last_price.price
            future_df['price_volatility'] = 0
            future_df['store_price_diff'] = 0
        else:
            return []

        # Scale features
        X_future = self.scaler.transform(future_df[self.feature_columns])

        # Make predictions
        predictions = self.model.predict(X_future)

        # Format results
        results = []
        for date, price in zip(future_dates, predictions):
            results.append({
                'date': date.date().isoformat(),
                'predicted_price': float(price),
                'confidence': float(self.model.score(X_future, predictions))
            })

        return results

    def save_model(self, product_id: int) -> None:
        """Save the trained model to disk."""
        if self.model:
            model_path = f"models/price_predictor_{product_id}.joblib"
            joblib.dump({
                'model': self.model,
                'scaler': self.scaler
            }, model_path)

    def load_model(self, product_id: int) -> None:
        """Load a trained model from disk."""
        model_path = f"models/price_predictor_{product_id}.joblib"
        try:
            saved_model = joblib.load(model_path)
            self.model = saved_model['model']
            self.scaler = saved_model['scaler']
        except:
            self.model = None
            self.scaler = StandardScaler()

class PricePredictionService:
    def __init__(self, db: Session):
        self.db = db
        self.predictors = {}

    def get_predictor(self, product_id: int) -> PricePredictor:
        """Get or create a price predictor for a product."""
        if product_id not in self.predictors:
            product = self.db.query(Product).get(product_id)
            if not product:
                raise ValueError(f"Product {product_id} not found")
            
            predictor = PricePredictor(self.db)
            predictor.load_model(product_id)
            self.predictors[product_id] = predictor
        
        return self.predictors[product_id]

    async def predict_prices(self, product_id: int, days: int = 30) -> List[Dict]:
        """Predict prices for a product."""
        predictor = self.get_predictor(product_id)
        product = self.db.query(Product).get(product_id)
        
        if not predictor.model:
            predictor.train(product)
            predictor.save_model(product_id)
        
        return predictor.predict(product, days)

    async def update_predictions(self, product_id: int) -> None:
        """Update price predictions for a product."""
        predictor = self.get_predictor(product_id)
        product = self.db.query(Product).get(product_id)
        
        predictor.train(product)
 