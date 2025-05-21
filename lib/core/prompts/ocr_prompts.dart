// File chứa các prompt liên quan đến chức năng OCR

/// Prompt chính được sử dụng cho API OCR để trích xuất thông tin hóa đơn.
const String ocrPrompt = """
Analyze the following bill image and Return ONLY a valid JSON object with the structured data.
NO explanatory text, NO markdown code blocks.

If a field cannot be inferred, the value is the EMPTY STRING: "" for strings, or 0 for numbers where applicable (like tax, tip, discount), or an empty array [] for items.
First, determine if the image is a receipt/bill/invoice. Set "is_receipt" accordingly. If it is NOT a receipt, provide a brief category description in "image_category" and leave other bill-related fields empty or with default values (0, "", []). If it IS a receipt, extract all other fields as accurately as possible and you can omit "image_category".

JSON fields MUST be:
- "is_receipt": (boolean, true if the document is likely a bill/invoice/receipt, false otherwise)
- "image_category": (string, if is_receipt is true then determine what category: "bill", "invoice", "receipt". If is_receipt is false then briefly describe the main content of the image and put an emoji before the description. If unable to determine 'unknown')
- "bill_date": (string, YYYY-MM-DD, bill date or payment date)
- "description": (string, store name or a general description)
- "currency_code": (string, e.g., "USD", "RUB", "VND", based on the main language of the bill)
- "subtotal_amount": (number, subtotal before tax/tip/discount, 0 if not found)
- "tax_amount": (number, total tax amount, 0 if not found)
- "tip_amount": (number, total tip amount, 0 if not found)
- "discount_amount": (number, total discount amount, 0 if not found)
- "total_amount": (number, the final total amount paid, 0 if not found)
- "items": (array of objects: {"description": string, "quantity": number, "unit_price": number, "total_price": number})

Extract the items listed on the bill. For each item, determine its description, quantity (default to 1 if not specified), unit price (if available), and total price. If only the total price for an item line is available, use that for "total_price" and potentially estimate "unit_price" if quantity is known. If quantity or unit price is ambiguous, make a reasonable guess or omit the field. Ensure the sum of "total_price" for all items is reasonably close to the "subtotal_amount" if available.
""";
