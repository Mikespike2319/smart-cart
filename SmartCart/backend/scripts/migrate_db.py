import os
import sys
from alembic.config import Config
from alembic import command
from dotenv import load_dotenv

# Add the parent directory to the Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def run_migrations() -> None:
    # Load environment variables
    load_dotenv()

    # Create Alembic configuration
    alembic_cfg = Config("alembic.ini")

    # Run the migration
    command.upgrade(alembic_cfg, "head")

def main() -> None:
    try:
        run_migrations()
        print("Database migrations completed successfully!")
    except Exception as e:
        print(f"Error running migrations: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main() 