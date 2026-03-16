# E-Commerce Backend API

A fully functional e-commerce backend built with Swift and Vapor 4, including user authentication, product management, shopping cart, and order processing.

## Features

- 👥 **User Authentication & Authorization** - JWT-based authentication with role-based access control (admin/customer)
- 🛍️ **Product Management** - Create, read, update, delete products and categories (admin only)
- 🛒 **Shopping Cart** - Add/remove items, manage quantities, calculate totals
- 📦 **Orders** - Checkout, order history, order status tracking
- 💳 **Payment Simulation** - Simulate payment processing
- 🔐 **Security** - JWT tokens, password hashing, role-based middleware
- 📊 **Database** - PostgreSQL with Fluent ORM
- 🎯 **RESTful API** - Clean, standard API endpoints with pagination

## Prerequisites

- **Swift 5.9+** (or later)
- **PostgreSQL 12+**
- **macOS 13+** or **Linux**

## Installation & Setup

### Step 1: Install PostgreSQL

**macOS (using Homebrew):**
```bash
brew install postgresql@15
brew services start postgresql@15
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib
sudo systemctl start postgresql
```

### Step 2: Create Database

```bash
createdb ecommerce
```

Or with psql:
```bash
psql -U postgres
CREATE DATABASE ecommerce;
\q
```

### Step 3: Clone the Project and Update Dependencies

```bash
cd /path/to/ecommerce
swift package update
```

### Step 4: Create .env File

Copy `.env.example` to `.env` and update values if needed:

```bash
cp .env.example .env
```

Edit `.env` to match your PostgreSQL credentials:
```
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=ecommerce
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=postgres
JWT_SECRET=your-secure-secret-key-here
APP_URL=http://localhost:8080
```

### Step 5: Run Migrations

```bash
swift run ECommerce migrate
```

This will create all tables and seed the database with:
- Admin user: `admin@example.com` / `admin123`
- Sample categories: Electronics, Clothing, Books
- Sample products in each category

### Step 6: Start the Server

```bash
swift run ECommerce serve
```

Server starts on `http://localhost:8080`

## API Endpoints

### Authentication

- `POST /api/auth/register` - Register new customer
- `POST /api/auth/login` - Login and get JWT token

### Categories (Admin only)

- `GET /api/categories` - List all categories
- `POST /api/categories` - Create category
- `PUT /api/categories/:id` - Update category
- `DELETE /api/categories/:id` - Delete category

### Products

- `GET /api/products` - List products (public, with pagination/filtering)
- `GET /api/products/:id` - Get product details
- `POST /api/products` - Create product (admin only)
- `PUT /api/products/:id` - Update product (admin only)
- `DELETE /api/products/:id` - Delete product (admin only)

### Shopping Cart (Authenticated)

- `GET /api/cart` - Get current cart
- `POST /api/cart/items` - Add item to cart
- `PUT /api/cart/items/:id` - Update item quantity
- `DELETE /api/cart/items/:id` - Remove item
- `DELETE /api/cart` - Clear cart

### Orders (Authenticated)

- `POST /api/orders/checkout` - Convert cart to order
- `GET /api/orders` - List user's orders (admin sees all)
- `GET /api/orders/:id` - Get order details
- `POST /api/orders/:id/pay` - Process payment (simulated)

## Example Requests

### Register
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "John Doe",
    "email": "john@example.com",
    "password": "password123"
  }'
```

### Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "admin123"
  }'
```

### Get Products
```bash
curl http://localhost:8080/api/products?limit=10&offset=0
```

### Add to Cart (requires token)
```bash
curl -X POST http://localhost:8080/api/cart/items \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_id": "product-uuid",
    "quantity": 2
  }'
```

### Checkout
```bash
curl -X POST http://localhost:8080/api/orders/checkout \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

### Process Payment
```bash
curl -X POST http://localhost:8080/api/orders/order-uuid/pay \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "payment_method": "credit_card"
  }'
```

## Project Structure

```
Sources/ECommerce/
├── Models/                 # Fluent models
│   ├── User.swift
│   ├── Category.swift
│   ├── Product.swift
│   ├── Cart.swift
│   └── Order.swift
├── Controllers/            # Route handlers
│   ├── AuthController.swift
│   ├── CategoryController.swift
│   ├── ProductController.swift
│   ├── CartController.swift
│   └── OrderController.swift
├── Migrations/            # Database migrations
│   ├── CreateUser.swift
│   ├── CreateCategory.swift
│   ├── CreateProduct.swift
│   ├── CreateCart.swift
│   ├── CreateOrder.swift
│   └── SeedDatabase.swift
├── Middleware/            # Custom middleware
│   └── AuthMiddleware.swift
├── DTOs/                  # Data transfer objects
│   ├── AuthDTOs.swift
│   ├── ProductDTOs.swift
│   └── CartDTOs.swift
├── configure.swift        # App configuration
├── routes.swift          # Route definitions
└── entrypoint.swift      # Application entry point
```

## Testing

You can use Postman, Insomnia, or curl to test the API. Here are some quick tests:

1. **Register a customer** using `/api/auth/register`
2. **Login** using `/api/auth/login` to get JWT token
3. **Browse products** using `/api/products`
4. **Add items to cart** using `/api/cart/items`
5. **Checkout** using `/api/orders/checkout`
6. **Pay for order** using `/api/orders/:id/pay`

## Troubleshooting

**Database connection error:**
- Ensure PostgreSQL is running: `brew services list`
- Check database name, username, and password in `.env`
- Verify database exists: `psql -U postgres -l`

**Port 8080 already in use:**
- Change the port by setting `--port` when running: `swift run ECommerce serve --port 8081`

**Migration errors:**
- Delete and recreate the database: `dropdb ecommerce && createdb ecommerce`
- Re-run migrations

## Environment Variables

- `DATABASE_HOST` - PostgreSQL host (default: localhost)
- `DATABASE_PORT` - PostgreSQL port (default: 5432)
- `DATABASE_NAME` - Database name (default: ecommerce)
- `DATABASE_USERNAME` - PostgreSQL username (default: postgres)
- `DATABASE_PASSWORD` - PostgreSQL password (default: postgres)
- `JWT_SECRET` - Secret key for JWT signing (required in production)
- `APP_URL` - Application URL (optional)

## Production Considerations

- [ ] Use proper password hashing (bcrypt) instead of plain text
- [ ] Implement rate limiting
- [ ] Add input validation and sanitization
- [ ] Use HTTPS in production
- [ ] Implement proper error logging
- [ ] Add API documentation (Swagger/OpenAPI)
- [ ] Implement caching strategies
- [ ] Add comprehensive testing
- [ ] Set up monitoring and alerting
- [ ] Implement proper transaction handling
- [ ] Add email notifications for orders
- [ ] Implement inventory management workflows

## See Also

- [Vapor Website](https://vapor.codes)
- [Vapor Documentation](https://docs.vapor.codes)
- [Fluent Documentation](https://docs.vapor.codes/fluent/overview)
- [JWT Authentication](https://docs.vapor.codes/security/jwt)
- [PostgreSQL Driver](https://github.com/vapor/fluent-postgres-driver)
