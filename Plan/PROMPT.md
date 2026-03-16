# E-Commerce Backend in Vapor – Prompt

Use the following prompt to generate a fully functional ecommerce backend in Swift using Vapor 4. The prompt includes all necessary details: models, endpoints, authentication, database setup, and local hosting instructions.

---

You are an expert Vapor developer with 10 years of experience. Generate a fully functional ecommerce backend in Swift using Vapor 4. The backend should include all necessary features for a basic ecommerce platform. It must be ready to run locally on a Mac or Linux with PostgreSQL as the database. Provide complete code, including Package.swift, models, controllers, migrations, routes, and any configuration files. Follow best practices and ensure the code is production-ready with proper error handling, validation, and security.

**Requirements:**

1. **User Authentication & Authorization**
   - User model: `id`, `fullName`, `email`, `passwordHash`, `role` (admin/customer), `createdAt`, `updatedAt`.
   - Endpoints: 
     - `POST /api/auth/register` – register new customer (auto role=customer).
     - `POST /api/auth/login` – returns JWT token.
     - `POST /api/auth/logout` – (optional, can be client‑side).
   - Use JWT for authentication (symmetric key from env). Protect routes with a `Authenticator` middleware.
   - Admin-only access for product/category management (use `RoleMiddleware`).

2. **Product Management**
   - Category model: `id`, `name`, `description`, `createdAt`.
   - Product model: `id`, `name`, `description`, `price` (Decimal), `stockQuantity` (Int), `categoryId` (foreign key), `imageUrls` ([String]), `createdAt`, `updatedAt`.
   - Endpoints (admin only):
     - `POST /api/categories` – create category.
     - `GET /api/categories` – list all.
     - `PUT /api/categories/:id` – update.
     - `DELETE /api/categories/:id` – delete (if no products).
     - `POST /api/products` – create product.
     - `GET /api/products` – list all (public, with optional filtering by category, pagination).
     - `GET /api/products/:id` – get one.
     - `PUT /api/products/:id` – update.
     - `DELETE /api/products/:id` – delete.

3. **Shopping Cart**
   - Cart is per user (one active cart). Use a `Cart` model with `id`, `userId`, `createdAt`, `updatedAt`. A `CartItem` model: `id`, `cartId`, `productId`, `quantity`, `addedAt`.
   - Endpoints (authenticated users):
     - `GET /api/cart` – retrieve current cart with items (populate product details).
     - `POST /api/cart/items` – add item (body: `productId`, `quantity`). If item exists, update quantity.
     - `PUT /api/cart/items/:id` – update quantity.
     - `DELETE /api/cart/items/:id` – remove item.
     - `DELETE /api/cart` – clear cart.

4. **Orders**
   - Order model: `id`, `userId`, `total` (Decimal), `status` (enum: pending, paid, shipped, delivered), `createdAt`, `updatedAt`.
   - OrderItem model: `id`, `orderId`, `productId`, `productName` (snapshot), `productPrice` (snapshot), `quantity`, `subtotal`.
   - Endpoints:
     - `POST /api/orders/checkout` – convert current cart into an order (calculates total, reduces stock, clears cart). Creates order with status `pending`.
     - `GET /api/orders` – list user’s orders (admin sees all).
     - `GET /api/orders/:id` – get order details with items.

5. **Payment Simulation**
   - `POST /api/orders/:id/pay` – simulate payment (body: `paymentMethod`). Validate order belongs to user, status `pending`. Update order status to `paid` and return success. (No real gateway integration.)

6. **Database & Migrations**
   - Use Fluent with PostgreSQL driver.
   - Provide migration files for all models (create tables, foreign keys, indexes).
   - Include a seed migration that creates an admin user (email: `admin@example.com`, password: `admin123`) and a few sample categories/products for testing.

7. **Environment Configuration**
   - Use `.env` file for:
     - `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_NAME`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`
     - `JWT_SECRET` (a strong secret key)
     - `APP_URL` (optional)
   - Load via `Environment` in `configure.swift`.

8. **Validation & Error Handling**
   - Validate input (e.g., email format, non‑empty strings, positive quantity/price).
   - Return appropriate HTTP status codes (200, 201, 400, 401, 403, 404, etc.) with JSON error messages.
   - Handle database errors gracefully.

9. **Project Structure**
   - Organize code into:
     - `Models/` – Fluent models.
     - `Controllers/` – route logic.
     - `Migrations/` – schema migrations.
     - `Middleware/` – authentication, role checks.
     - `DTOs/` – request/response structs (e.g., `RegisterRequest`, `ProductResponse`).
     - `configure.swift`, `routes.swift`.

10. **Local Setup Instructions**
    - Include a `README.md` with steps:
      1. Install PostgreSQL and create database.
      2. Clone the project, run `swift package update`.
      3. Create `.env` file from `.env.example`.
      4. Run migrations: `swift run App migrate`.
      5. (Optional) Run seed: `swift run App seed` or use auto‑migration seed.
      6. Start server: `swift run App serve`.
      7. Test with tools like Postman or curl.

**Additional Notes:**
- Use SwiftNIO for concurrency.
- Comment code where necessary, especially complex logic.
- Ensure all endpoints are RESTful and return consistent JSON structures.
- Use `Decimal` for monetary values to avoid floating‑point errors.
- Include pagination on list endpoints (limit/offset).
- Use `async`/`await` (Vapor 4 supports it).

Generate the complete codebase with all files and folders. The final answer should be the full code, ready to be copied and run.