# Postman Guide for E-Commerce API

Complete guide to testing the E-Commerce API using Postman with provided collection and environment files.

## 📥 Import Files into Postman

### Step 1: Download Files
- **Collection:** `E-Commerce-API.postman_collection.json`
- **Environment:** `E-Commerce-API.postman_environment.json`

### Step 2: Import Collection
1. Open **Postman**
2. Click **Import** button (top left)
3. Select **E-Commerce-API.postman_collection.json**
4. Click **Import**

### Step 3: Import Environment
1. Click the **Environments** icon (left sidebar)
2. Click **Import**
3. Select **E-Commerce-API.postman_environment.json**
4. Click **Import**

### Step 4: Select Environment
1. Click the environment dropdown (top right, currently says "No Environment")
2. Select **E-Commerce API - Local**

## 🚀 Quick Start Testing Flow

### Prerequisites
- E-Commerce server running: `swift run ECommerce serve`
- PostgreSQL running
- Postman open with collection and environment imported

### Testing Workflow

#### 1. **Authentication - Register New User**
- **Request:** `Authentication → Register User`
- **Update body:** Change email/password as needed
- **Send Request**
- **Response:** You'll get a token in the response

#### 2. **Authentication - Login (Admin)**
- **Request:** `Authentication → Login`
- **Default credentials:**
  - Email: `admin@example.com`
  - Password: `admin123`
- **Send Request**
- **Copy token from response and save to `{{auth_token}}` variable**

```json
// Response example:
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "email": "admin@example.com",
  "full_name": "Admin User",
  "role": "admin",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### 3. **Products - List All**
- **Request:** `Products → List Products`
- **No auth required** (public endpoint)
- **Send Request**
- **Save a `product_id` from response to variables**

#### 4. **Categories - List All**
- **Request:** `Categories → List Categories`
- **No auth required** (public endpoint)
- **Send Request**
- **Save a `category_id` from response to variables**

#### 5. **Shopping Cart - Get Cart**
- **Request:** `Shopping Cart → Get Cart`
- **Auth required:** Bearer token (uses `{{auth_token}}`)
- **Send Request**
- **You'll get an empty cart initially**

#### 6. **Shopping Cart - Add Item**
- **Request:** `Shopping Cart → Add Item to Cart`
- **Update body:** Replace `{{product_id}}` with actual product ID
- **Auth required:** Bearer token
- **Send Request**
- **Response includes updated cart with items**

#### 7. **Shopping Cart - Add More Items**
- Repeat the "Add Item" request with different products or quantities
- Build up your cart

#### 8. **Orders - Checkout**
- **Request:** `Orders → Checkout (Create Order)`
- **Auth required:** Bearer token
- **Send Request**
- **Response:** Order confirmation with `order_id`
- **Save the `order_id` from response to variables**

#### 9. **Orders - Pay for Order**
- **Request:** `Orders → Pay for Order`
- **Update URL:** Replace `{{order_id}}` with the order ID from step 8
- **Auth required:** Bearer token
- **Send Request**
- **Response:** Order status updated to "paid"

#### 10. **Orders - List & Get Details**
- **Request:** `Orders → List Orders`
- **Send Request** - See all your orders
- **Request:** `Orders → Get Order Details`
- **Send Request** - See complete order information

## 📋 API Endpoints Reference

### Authentication (No Auth Required)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new customer |
| POST | `/api/auth/login` | Login and get JWT token |

### Categories (List is public, CRUD admin only)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/categories` | ❌ | List all categories |
| GET | `/api/categories/:id` | ❌ | Get category details |
| POST | `/api/categories` | ✅ | Create category (admin) |
| PUT | `/api/categories/:id` | ✅ | Update category (admin) |
| DELETE | `/api/categories/:id` | ✅ | Delete category (admin) |

### Products (List/Get public, CRUD admin only)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/products` | ❌ | List products (paginated) |
| GET | `/api/products/:id` | ❌ | Get product details |
| POST | `/api/products` | ✅ | Create product (admin) |
| PUT | `/api/products/:id` | ✅ | Update product (admin) |
| DELETE | `/api/products/:id` | ✅ | Delete product (admin) |

### Shopping Cart (Auth Required)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/cart` | Get current cart |
| POST | `/api/cart/items` | Add item to cart |
| PUT | `/api/cart/items/:id` | Update item quantity |
| DELETE | `/api/cart/items/:id` | Remove item from cart |
| DELETE | `/api/cart` | Clear entire cart |

### Orders (Auth Required)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/orders` | List user's orders |
| GET | `/api/orders/:id` | Get order details |
| POST | `/api/orders/checkout` | Convert cart to order |
| POST | `/api/orders/:id/pay` | Process payment |

## 🔧 Environment Variables

Update these in Postman as you test:

```
base_url        → http://localhost:8080 (default)
auth_token      → Copy from login response
category_id     → Copy from category list response
product_id      → Copy from product list response
cart_item_id    → Copy from get cart response
order_id        → Copy from checkout response
user_id         → Copy from auth response
```

### How to Update Variables
1. Click **Collections** (left sidebar)
2. Select **E-Commerce API**
3. Click **Variables** tab
4. Update values in "Current Value" column
5. Changes apply automatically to all requests

## 📝 Sample Test Scenarios

### Scenario 1: Admin Setup
1. Login with admin credentials
2. Create new category
3. Create new product in that category
4. Verify product appears in list

### Scenario 2: Customer Purchase
1. Register new customer account
2. Login with new credentials
3. Browse products
4. Add items to cart
5. Checkout (create order)
6. Pay for order
7. Check order history

### Scenario 3: Cart Management
1. Login as customer
2. Get cart (should be empty)
3. Add multiple items
4. Update item quantities
5. View cart total
6. Remove specific items
7. Clear entire cart

## ⚠️ Common Issues & Solutions

### "Authorization Failed" / 401 Error
- **Cause:** Missing or invalid token
- **Solution:**
  1. Run login request again
  2. Copy the token from response
  3. Paste into `{{auth_token}}` variable
  4. Ensure Bearer prefix is in Authorization header

### "Unauthorized" / 403 Error (Admin Endpoints)
- **Cause:** Using customer account on admin-only endpoint
- **Solution:** Login with admin credentials (`admin@example.com` / `admin123`)

### "Not Found" / 404 Error
- **Cause:** ID doesn't exist or placeholder variable not updated
- **Solution:**
  1. Verify ID exists (list endpoints first)
  2. Update variable: `{{variable_name}}`
  3. Copy correct ID from previous response

### "Bad Request" / 400 Error
- **Cause:** Invalid request body or missing required fields
- **Solution:**
  1. Check request body JSON is valid
  2. Verify all required fields are present
  3. Check field names match API spec

## 🔍 Debugging Tips

### Enable Request/Response Logging
1. Send a request
2. Open **Tests** tab to see response details
3. Check response headers and body
4. Use **Console** (bottom of Postman) to see full logs

### Validate JSON
- If you get parsing errors, use **JSONLint** to validate request body
- Check that quotes and braces are properly closed

### Check Bearer Token Format
- Request should have header: `Authorization: Bearer <token>`
- Postman usually formats this automatically
- Check in **Headers** tab if having issues

## 📚 Additional Resources

- [Postman Documentation](https://learning.postman.com/)
- [API Documentation](../README.md)
- [JWT Tokens](https://jwt.io/)

## 🎯 Testing Checklist

- [ ] Environment imported and selected
- [ ] Collection imported
- [ ] Server running (`swift run ECommerce serve`)
- [ ] PostgreSQL running
- [ ] Base URL correct (`http://localhost:8080`)
- [ ] Admin login successful
- [ ] Token saved to `{{auth_token}}`
- [ ] Can list products
- [ ] Can add items to cart
- [ ] Can checkout
- [ ] Can pay for order

---

**Happy Testing! 🚀**

For issues or questions about the API, refer to the main README.md in the project root.
