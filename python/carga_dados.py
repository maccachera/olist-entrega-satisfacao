import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
from sqlalchemy.types import String

load_dotenv()

url = URL.create(
    "mysql+pymysql",
    username=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST", "127.0.0.1"),
    port=int(os.getenv("DB_PORT", 3306)),
    database=os.getenv("DB_NAME"),
    query={"charset": "utf8mb4"},
)
engine = create_engine(url)

RAW = Path(__file__).resolve().parent.parent / "data" / "raw"

# arquivo CSV -> (nome da tabela, colunas de data)
ARQUIVOS = {
    "olist_customers_dataset.csv": ("customers", []),
    "olist_geolocation_dataset.csv": ("geolocation", []),
    "olist_order_items_dataset.csv": ("order_items", ["shipping_limit_date"]),
    "olist_order_payments_dataset.csv": ("order_payments", []),
    "olist_order_reviews_dataset.csv": (
        "order_reviews",
        ["review_creation_date", "review_answer_timestamp"],
    ),
    "olist_orders_dataset.csv": (
        "orders",
        [
            "order_purchase_timestamp",
            "order_approved_at",
            "order_delivered_carrier_date",
            "order_delivered_customer_date",
            "order_estimated_delivery_date",
        ],
    ),
    "olist_products_dataset.csv": ("products", []),
    "olist_sellers_dataset.csv": ("sellers", []),
    "product_category_name_translation.csv": ("category_translation", []),
}

for arquivo, (tabela, colunas_data) in ARQUIVOS.items():
    df = pd.read_csv(RAW / arquivo)

    for col in colunas_data:
        df[col] = pd.to_datetime(df[col], errors="coerce")

    
    tipos = {c: String(40) for c in df.columns if c.endswith("_id")}

    df.to_sql(
        tabela,
        engine,
        if_exists="replace",
        index=False,
        dtype=tipos,
        chunksize=5000,
        method="multi",
    )

    with engine.connect() as conn:
        total = conn.execute(text(f"SELECT COUNT(*) FROM {tabela}")).scalar()
    print(f"{tabela}: {len(df)} linhas no CSV -> {total} no MySQL")

print("Carga concluída.")