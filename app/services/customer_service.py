from copy import deepcopy

from app.mock_data.banker import CUSTOMERS


def get_customers():
    """Danh sách khách hàng — sau này gọi vw_Customers."""
    return deepcopy(CUSTOMERS)


def create_customer(full_name, email, phone_number, address, birth_day, username, password):
    """Tạo khách hàng — sau này gọi sp_CreateCustomer."""
    return {
        "success": True,
        "message": f"Đã tạo khách hàng {full_name} thành công (mock).",
        "data": {
            "customer_id": 99,
            "username": username,
            "full_name": full_name,
        },
    }
