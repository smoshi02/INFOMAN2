import random
from datetime import datetime, timedelta

# ----------------------------
# CONFIGURATION
# ----------------------------
NUM_CUSTOMERS = 500
NUM_PRODUCTS = 80
NUM_BRANCHES = 30
NUM_TRANSACTIONS = 100000
START_DATE = datetime(2020, 1, 1)

OUTPUT_FILE = "seed_data.sql"

# ----------------------------
# DATA OPTIONS
# ----------------------------

names = [
"Juan Dela Cruz","Maria Santos","Jose Reyes","Ana Cruz","Carlos Mendoza",
"Mark Bautista","Erika Ramos","Miguel Tan","Catherine Aquino","Victor Lopez",
"Sofia Garcia","Paolo Villanueva","Rica Fernandez","Kevin Lim","Angela Torres",
"Joshua Castro","Daniel Flores","Carla Gutierrez","Paula Navarro","Kristine Ramos"
]

regions = [
"NCR","CAR","Region I","Region II","Region III",
"Region IV-A","Region IV-B","Region V","Region VI",
"Region VII","Region VIII","Region IX","Region X",
"Region XI","Region XII","Region XIII","BARMM"
]

cities = [
"Manila","Quezon City","Makati","Taguig","Pasig","Baguio",
"San Fernando","Cebu City","Davao City","Zamboanga City",
"Iloilo City","Bacolod","Tacloban","Cagayan de Oro",
"General Santos","Butuan","Vigan","Dagupan","Angeles"
]

product_categories = {
"Beverage":[
"Espresso","Americano","Latte","Cappuccino","Mocha",
"Flat White","Macchiato","Cold Brew","Frappuccino",
"Caramel Macchiato","Vanilla Latte","Hazelnut Latte",
"Iced Coffee","Iced Mocha","Matcha Latte","Chai Latte"
],
"Food":[
"Croissant","Bagel","Sandwich","Panini","Wrap",
"Grilled Cheese","Breakfast Burrito","Quiche","Toast"
],
"Snack":[
"Cookie","Brownie","Donut","Muffin","Danish",
"Chocolate Cake","Cheesecake","Granola Bar"
],
"Merchandise":[
"Coffee Mug","Tumbler","Coffee Beans 250g",
"Coffee Beans 500g","French Press","Pour-over Kit"
]
}

# ----------------------------
# GENERATE PRODUCTS LIST
# ----------------------------
products = []
for category, items in product_categories.items():
    for item in items:
        products.append({
            "name": item,
            "category": category,
            "price": round(random.uniform(80,300),2)
        })

# limit number of products if needed
products = products[:NUM_PRODUCTS]

# ----------------------------
# WRITE SQL FILE
# ----------------------------

with open(OUTPUT_FILE,"w",encoding="utf-8") as f:

    # ----------------------------
    # CUSTOMERS
    # ----------------------------
    f.write("-- Customers\n")
    for i in range(NUM_CUSTOMERS):
        name = random.choice(names)
        region = random.choice(regions)

        f.write(
        f"INSERT INTO public.customers (full_name, region_code) "
        f"VALUES ('{name}', '{region}');\n"
        )

    # ----------------------------
    # PRODUCTS
    # ----------------------------
    f.write("\n-- Products\n")

    for p in products:
        f.write(
        f"INSERT INTO public.products (product_name, category, unit_price) "
        f"VALUES ('{p['name']}', '{p['category']}', {p['price']});\n"
        )

    # ----------------------------
    # BRANCHES
    # ----------------------------
    f.write("\n-- Branches\n")

    for i in range(NUM_BRANCHES):
        city = random.choice(cities)
        region = random.choice(regions)

        f.write(
        f"INSERT INTO public.branches (branch_name, city, region) "
        f"VALUES ('{city} Coffee Branch', '{city}', '{region}');\n"
        )

    # ----------------------------
    # SALES TRANSACTIONS
    # ----------------------------
    f.write("\n-- Sales Transactions\n")

    for i in range(NUM_TRANSACTIONS):

        date = START_DATE + timedelta(days=random.randint(0,1500))

        customer = random.randint(1,NUM_CUSTOMERS)
        product = random.randint(1,len(products))
        branch = random.randint(1,NUM_BRANCHES)

        qty = random.randint(1,5)

        price = products[product-1]["price"]

        f.write(
        f"INSERT INTO public.sales_txn "
        f"(txn_date, customer_id, product_id, branch_id, qty, unit_price) "
        f"VALUES "
        f"('{date.date()}', {customer}, {product}, {branch}, {qty}, {price});\n"
        )

print("SQL seed file created:", OUTPUT_FILE)