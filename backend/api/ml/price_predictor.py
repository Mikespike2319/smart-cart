import numpy as np
from sklearn.linear_model import LinearRegression
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from typing import List, Dict, Optional
import joblib
import os
from datetime import datetime, timedelta

class PricePredictor:
    def __init__(self):
        self.model = RandomForestRegressor(
            n_estimators=100,
            max_depth=10,
            random_state=42
        )
        self.scaler = StandardScaler()
        self.model_path = "models/price_predictor.joblib"
        self.scaler_path = "models/price_scaler.joblib"
        
        # Create models directory if it doesn't exist
        os.makedirs("models", exist_ok=True)
        
        # Load existing model if available
        if os.path.exists(self.model_path) and os.path.exists(self.scaler_path):
            self.model = joblib.load(self.model_path)
            self.scaler = joblib.load(self.scaler_path)

    def prepare_features(self, price_history: List[Dict]) -> np.ndarray:
        """Prepare features for price prediction."""
        features = []
        for price in price_history:
            # Extract features from price data
            day_of_week = price["timestamp"].weekday()
            month = price["timestamp"].month
            is_sale = 1 if price["is_sale"] else 0
            
            features.append([
                day_of_week,
                month,
                is_sale,
                price["price"]
            ])
        
        return np.array(features)

    def train(self, price_history: List[Dict]):
        """Train the price prediction model."""
        if not price_history:
            return
        
        # Prepare features and target
        X = self.prepare_features(price_history)
        y = X[:, -1]  # Last column is the price
        X = X[:, :-1]  # Remove price from features
        
        # Scale features
        X_scaled = self.scaler.fit_transform(X)
        
        # Train model
        self.model.fit(X_scaled, y)
        
        # Save model and scaler
        joblib.dump(self.model, self.model_path)
        joblib.dump(self.scaler, self.scaler_path)

    def predict(self, 
                current_price: float,
                is_sale: bool,
                days_ahead: int = 7) -> List[Dict]:
        """Predict future prices."""
        predictions = []
        
        # Generate features for future dates
        for day in range(1, days_ahead + 1):
            future_date = datetime.utcnow() + timedelta(days=day)
            
            features = np.array([[
                future_date.weekday(),
                future_date.month,
                1 if is_sale else 0
            ]])
            
            # Scale features
            features_scaled = self.scaler.transform(features)
            
            # Make prediction
            predicted_price = self.model.predict(features_scaled)[0]
            
            # Calculate confidence based on feature importance
            confidence = 0.8  # This would be calculated based on model metrics
            
            predictions.append({
                "days_ahead": day,
                "predicted_price": float(predicted_price),
                "confidence": confidence
            })
        
        return predictions

    def evaluate(self, price_history: List[Dict]) -> Dict:
        """Evaluate model performance."""
        if not price_history:
            return {"error": "No price history available for evaluation"}
        
        # Prepare features and target
        X = self.prepare_features(price_history)
        y = X[:, -1]  # Last column is the price
        X = X[:, :-1]  # Remove price from features
        
        # Scale features
        X_scaled = self.scaler.transform(X)
        
        # Make predictions
        y_pred = self.model.predict(X_scaled)
        
        # Calculate metrics
        mse = np.mean((y - y_pred) ** 2)
        rmse = np.sqrt(mse)
        mae = np.mean(np.abs(y - y_pred))
        
        return {
            "mse": float(mse),
            "rmse": float(rmse),
            "mae": float(mae),
            "feature_importance": dict(zip(
                ["day_of_week", "month", "is_sale"],
                self.model.feature_importances_
            ))
        } 