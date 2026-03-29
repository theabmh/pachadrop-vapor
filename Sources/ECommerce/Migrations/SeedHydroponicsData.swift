import Fluent
import Vapor

struct SeedHydroponicsData: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Remove old generic seed products and categories
        let oldCategoryNames: Set<String> = ["Electronics", "Clothing", "Books"]
        let oldCategories = try await Category.query(on: database).all()
            .filter { oldCategoryNames.contains($0.name) }

        for category in oldCategories {
            if let id = category.id {
                try await Product.query(on: database)
                    .filter(\.$category.$id == id)
                    .delete(force: true)
            }
            try await category.delete(force: true, on: database)
        }

        // ── Categories ──────────────────────────────────────────────────────
        let vegetables = Category(name: "Fresh Vegetables", description: "Farm-fresh and hydroponic vegetables, harvested daily")
        let fruits     = Category(name: "Fresh Fruits",     description: "Seasonal and exotic fruits, sourced from organic farms")
        let kits       = Category(name: "Hydroponics Kits", description: "Everything you need to grow your own food at home")
        let herbs      = Category(name: "Herbs & Microgreens", description: "Aromatic herbs and nutrient-dense microgreens")

        try await vegetables.save(on: database)
        try await fruits.save(on: database)
        try await kits.save(on: database)
        try await herbs.save(on: database)

        let vegID   = vegetables.id ?? UUID()
        let fruID   = fruits.id     ?? UUID()
        let kitID   = kits.id       ?? UUID()
        let herbID  = herbs.id      ?? UUID()

        // ── Fresh Vegetables ────────────────────────────────────────────────
        let products: [Product] = [
            Product(
                name: "Organic Spinach",
                description: "Tender baby spinach leaves grown without pesticides.",
                price: 2.99, stockQuantity: 200, categoryID: vegID,
                imageUrls: [],
                subtitle: "Fresh Farm Organic",
                detailDescription: "Our baby spinach is grown in a controlled hydroponic environment, ensuring crisp, pesticide-free leaves packed with iron and vitamins.",
                variant: "250g bundle",
                emoji: "🥬",
                cardTintHex: "#E8F5E9",
                imageURL: nil,
                savingsPercentage: nil,
                deliveryInfo: "Same day delivery"
            ),
            Product(
                name: "Cherry Tomatoes",
                description: "Vine-ripened cherry tomatoes bursting with sweetness.",
                price: 3.49, stockQuantity: 150, categoryID: vegID,
                imageUrls: [],
                subtitle: "Vine Ripened",
                detailDescription: "Grown on the vine in our hydroponic greenhouse for maximum sugar development. Perfect for salads, snacking, or roasting.",
                variant: "500g pack",
                emoji: "🍅",
                cardTintHex: "#FFEBEE",
                imageURL: nil,
                savingsPercentage: 10,
                deliveryInfo: "Same day delivery"
            ),
            Product(
                name: "English Cucumber",
                description: "Crisp, seedless cucumber with thin edible skin.",
                price: 1.99, stockQuantity: 180, categoryID: vegID,
                imageUrls: [],
                subtitle: "Hydroponic Grown",
                detailDescription: "Hydroponic-grown in a temperature-controlled environment. Thin skin means no need to peel — just wash and enjoy.",
                variant: "1 pc (300g - 400g)",
                emoji: "🥒",
                cardTintHex: "#F1F8E9",
                imageURL: nil,
                savingsPercentage: nil,
                deliveryInfo: "Same day delivery"
            ),
            Product(
                name: "Bell Pepper Mix",
                description: "A colourful trio of red, yellow, and green bell peppers.",
                price: 4.99, stockQuantity: 120, categoryID: vegID,
                imageUrls: [],
                subtitle: "Colorful & Crisp",
                detailDescription: "Hand-picked at peak ripeness and packed as a rainbow trio. Rich in Vitamin C — great raw, grilled, or stuffed.",
                variant: "3 pcs mixed",
                emoji: "🫑",
                cardTintHex: "#FFF8E1",
                imageURL: nil,
                savingsPercentage: 15,
                deliveryInfo: "Next day delivery"
            ),
            Product(
                name: "Broccoli",
                description: "Fresh whole broccoli head with tight, dark-green florets.",
                price: 2.49, stockQuantity: 160, categoryID: vegID,
                imageUrls: [],
                subtitle: "Farm Fresh",
                detailDescription: "Harvested fresh from our farm partners every morning. Dense florets and a tender stalk — steam, stir-fry, or roast.",
                variant: "1 pc (400g - 600g)",
                emoji: "🥦",
                cardTintHex: "#E8F5E9",
                imageURL: nil,
                savingsPercentage: nil,
                deliveryInfo: "Same day delivery"
            ),

            // ── Fresh Fruits ───────────────────────────────────────────────
            Product(
                name: "Strawberries",
                description: "Hand-picked strawberries, sweet and full of flavour.",
                price: 5.99, stockQuantity: 100, categoryID: fruID,
                imageUrls: [],
                subtitle: "Sweet & Juicy",
                detailDescription: "Grown in rich soil under natural sunlight. Each punnet is hand-graded for size and ripeness — ideal for desserts or smoothies.",
                variant: "250g punnet",
                emoji: "🍓",
                cardTintHex: "#FCE4EC",
                imageURL: nil,
                savingsPercentage: 10,
                deliveryInfo: "Same day delivery"
            ),
            Product(
                name: "Seedless Watermelon",
                description: "Refreshing, seedless watermelon — perfect for summer.",
                price: 8.99, stockQuantity: 60, categoryID: fruID,
                imageUrls: [],
                subtitle: "Seedless Premium",
                detailDescription: "Chilled and ready to slice. Our seedless watermelons are selected for Brix sweetness levels above 10 — guaranteed refreshing.",
                variant: "1 pc (3kg - 5kg)",
                emoji: "🍉",
                cardTintHex: "#E8F5E9",
                imageURL: nil,
                savingsPercentage: nil,
                deliveryInfo: "Next day delivery"
            ),
            Product(
                name: "Alphonso Mango",
                description: "The king of mangoes — rich, creamy, and aromatic.",
                price: 7.99, stockQuantity: 80, categoryID: fruID,
                imageUrls: [],
                subtitle: "King of Mangoes",
                detailDescription: "Sourced directly from Ratnagiri GI-certified farms. Naturally ripened, no carbide. Saffron flesh with a buttery, fiberless texture.",
                variant: "1 kg (4–5 pcs)",
                emoji: "🥭",
                cardTintHex: "#FFF9C4",
                imageURL: nil,
                savingsPercentage: 20,
                deliveryInfo: "Next day delivery"
            ),
            Product(
                name: "Blueberries",
                description: "Plump, antioxidant-rich blueberries from organic farms.",
                price: 4.99, stockQuantity: 90, categoryID: fruID,
                imageUrls: [],
                subtitle: "Antioxidant Rich",
                detailDescription: "Organic certified and harvested at peak ripeness. Exceptionally high in anthocyanins — great for smoothies, oatmeal, or snacking.",
                variant: "125g punnet",
                emoji: "🫐",
                cardTintHex: "#EDE7F6",
                imageURL: nil,
                savingsPercentage: nil,
                deliveryInfo: "Same day delivery"
            ),
            Product(
                name: "Avocado",
                description: "Creamy Hass avocado, ready to eat today.",
                price: 2.99, stockQuantity: 130, categoryID: fruID,
                imageUrls: [],
                subtitle: "Ready to Eat",
                detailDescription: "Ripeness-guaranteed Hass avocados. Dark skin, rich buttery flesh, perfect for toast, guacamole, or salads. Stone-in for longer freshness.",
                variant: "1 pc (180g - 220g)",
                emoji: "🥑",
                cardTintHex: "#F1F8E9",
                imageURL: nil,
                savingsPercentage: nil,
                deliveryInfo: "Same day delivery"
            ),

            // ── Hydroponics Kits ───────────────────────────────────────────
            Product(
                name: "Starter Hydroponic Kit",
                description: "All-in-one beginner kit to grow herbs and greens at home.",
                price: 49.99, stockQuantity: 50, categoryID: kitID,
                imageUrls: [],
                subtitle: "Grow at Home",
                detailDescription: "Includes a 10-pod deep water culture (DWC) tray, pH-balanced nutrient solution, grow medium, and seed pods for lettuce, basil, and mint. Setup in under 15 minutes.",
                variant: "10-pod system",
                emoji: "🌱",
                cardTintHex: "#E0F2F1",
                imageURL: nil,
                savingsPercentage: nil,
                deliveryInfo: "Delivered in 2-3 days"
            ),
            Product(
                name: "NFT Channel System",
                description: "Nutrient Film Technique system for continuous plant growth.",
                price: 129.99, stockQuantity: 20, categoryID: kitID,
                imageUrls: [],
                subtitle: "Professional Grade",
                detailDescription: "6-channel NFT system with pump, timer, and 2L nutrient reservoir. Supports 30 plants simultaneously — ideal for lettuce, spinach, and herbs. Food-safe PVC channels.",
                variant: "6-channel / 30-plant capacity",
                emoji: "🪴",
                cardTintHex: "#E8F5E9",
                imageURL: nil,
                savingsPercentage: nil,
                deliveryInfo: "Delivered in 3-5 days"
            ),
            Product(
                name: "Hydroponic Nutrient Solution",
                description: "Complete 3-part nutrient formula for all growth stages.",
                price: 14.99, stockQuantity: 200, categoryID: kitID,
                imageUrls: [],
                subtitle: "Complete Formula",
                detailDescription: "Professionally formulated NPK blend with micronutrients — Grow, Bloom, and Micro bottles. Suitable for all hydroponic systems including DWC, NFT, and coco coir.",
                variant: "1L concentrate (each bottle)",
                emoji: "💧",
                cardTintHex: "#E3F2FD",
                imageURL: nil,
                savingsPercentage: 5,
                deliveryInfo: "Delivered in 2-3 days"
            ),
            Product(
                name: "Full Spectrum LED Grow Light",
                description: "Energy-efficient grow light for indoor hydroponics.",
                price: 39.99, stockQuantity: 40, categoryID: kitID,
                imageUrls: [],
                subtitle: "Full Spectrum",
                detailDescription: "45W panel with 3000K + 5000K dual-spectrum LEDs. Covers a 60×60cm grow area. Built-in timer, daisy-chain support, and low heat output. Replaces 150W HPS.",
                variant: "45W / 60×60cm coverage",
                emoji: "💡",
                cardTintHex: "#FFF8E1",
                imageURL: nil,
                savingsPercentage: nil,
                deliveryInfo: "Delivered in 2-4 days"
            ),

            // ── Herbs & Microgreens ────────────────────────────────────────
            Product(
                name: "Fresh Basil",
                description: "Aromatic Italian basil, freshly cut with roots attached.",
                price: 1.99, stockQuantity: 250, categoryID: herbID,
                imageUrls: [],
                subtitle: "Aromatic Italian",
                detailDescription: "Living basil delivered with roots intact so it stays fresh for up to 2 weeks on your counter. Perfect for pasta, pizza, and pesto.",
                variant: "50g bunch",
                emoji: "🌿",
                cardTintHex: "#E8F5E9",
                imageURL: nil,
                savingsPercentage: nil,
                deliveryInfo: "Same day delivery"
            ),
            Product(
                name: "Spearmint",
                description: "Cool, refreshing spearmint for teas, cocktails, and cooking.",
                price: 1.49, stockQuantity: 230, categoryID: herbID,
                imageUrls: [],
                subtitle: "Spearmint Fresh",
                detailDescription: "Hydroponic-grown spearmint with intense aroma and flavour. Delivered living with roots — place in a glass of water on your windowsill to keep fresh for weeks.",
                variant: "30g bunch",
                emoji: "🌱",
                cardTintHex: "#F1F8E9",
                imageURL: nil,
                savingsPercentage: nil,
                deliveryInfo: "Same day delivery"
            ),
            Product(
                name: "Sunflower Microgreens",
                description: "Crunchy, nutty microgreens — among the most nutrient-dense foods.",
                price: 3.99, stockQuantity: 100, categoryID: herbID,
                imageUrls: [],
                subtitle: "Nutrient Dense",
                detailDescription: "Harvested at the 7-day stage for maximum nutrition. Up to 40× more vitamins than mature sunflower leaves. Add to sandwiches, salads, or smoothie bowls.",
                variant: "100g tray",
                emoji: "🌻",
                cardTintHex: "#FFFDE7",
                imageURL: nil,
                savingsPercentage: 10,
                deliveryInfo: "Next day delivery"
            ),
            Product(
                name: "Coriander",
                description: "Freshly harvested coriander with fragrant leaves and tender stems.",
                price: 1.29, stockQuantity: 280, categoryID: herbID,
                imageUrls: [],
                subtitle: "Garden Fresh",
                detailDescription: "Our coriander is cut-to-order each morning, ensuring maximum freshness and aroma. Essential for Indian, Mexican, and Thai cuisines.",
                variant: "40g bunch",
                emoji: "🌿",
                cardTintHex: "#E8F5E9",
                imageURL: nil,
                savingsPercentage: nil,
                deliveryInfo: "Same day delivery"
            )
        ]

        for product in products {
            try await product.save(on: database)
        }
    }

    func revert(on database: Database) async throws {
        let categoryNames: Set<String> = ["Fresh Vegetables", "Fresh Fruits", "Hydroponics Kits", "Herbs & Microgreens"]
        let categories = try await Category.query(on: database).all()
            .filter { categoryNames.contains($0.name) }

        for category in categories {
            if let id = category.id {
                try await Product.query(on: database)
                    .filter(\.$category.$id == id)
                    .delete(force: true)
            }
            try await category.delete(force: true, on: database)
        }
    }
}
