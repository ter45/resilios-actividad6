import { application } from "controllers/application"

import HelloController from "controllers/hello_controller"
import CartController from "controllers/cart_controller"
import SearchController from "controllers/search_controller"
import ScaleController from "controllers/scale_controller"
import ClosingController from "controllers/closing_controller"
import CreditPaymentController from "controllers/credit_payment_controller"

application.register("hello", HelloController)
application.register("cart", CartController)
application.register("search", SearchController)
application.register("scale", ScaleController)
application.register("closing", ClosingController)
application.register("credit-payment", CreditPaymentController)
