defmodule CoverflexWeb.OrderControllerTest do
  use CoverflexWeb.ConnCase

  alias Coverflex.Orders
  alias TestHelper.CoverflexWeb.Fixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create order" do
    test "renders order when data is valid", %{conn: conn} do
      assert length(Orders.list_orders()) == 0
      product1 = Fixtures.product_fixture()
      product2 = Fixtures.product_fixture()
      products = [product1.id, product2.id]
      balance = product1.price + product2.price

      user = Fixtures.user_fixture(%{balance: balance}, with_account: true)

      payload = %{"user_id" => user.user_id, "items" => products}
      conn = post(conn, Routes.order_path(conn, :create), order: payload)

      total_expected = product1.price + product2.price

      products_expected = [
        %{"id" => product1.id, "name" => product1.name, "price" => product1.price},
        %{"id" => product2.id, "name" => product2.name, "price" => product2.price}
      ]

      # {"order": {"order_id": "123", "data": {"items": [...], "total": 500}}}
      assert %{
               "order" => %{
                 "order_id" => _order_id,
                 "data" => %{"items" => ^products_expected, "total" => ^total_expected}
               }
             } = json_response(conn, 201)

      assert length(Orders.list_orders()) == 1
    end

    test "returns 404 when user not exist", %{conn: conn} do
      product1 = Fixtures.product_fixture()
      product2 = Fixtures.product_fixture()
      products = [product1.id, product2.id]

      payload = %{"user_id" => "invalid user id", "items" => products}
      conn = post(conn, Routes.order_path(conn, :create), order: payload)

      assert %{"error" => "user_not_found"} = json_response(conn, 404)
    end

    test "returns 404 when at least one product not exist", %{conn: conn} do
      product1 = Fixtures.product_fixture()
      invalid_product = "1979f1ef-ed8e-4bd3-9a6a-753901b3a9d4"
      products = [product1.id, invalid_product]
      user = Fixtures.user_fixture(%{balance: product1.price}, with_account: true)

      payload = %{"user_id" => user.user_id, "items" => products}
      conn = post(conn, Routes.order_path(conn, :create), order: payload)

      assert %{"error" => "products_not_found"} = json_response(conn, 404)
    end

    test "returns 400 when try to buy the same product twice", %{conn: conn} do
      product1 = Fixtures.product_fixture()
      products = [product1.id]
      user = Fixtures.user_fixture(%{balance: product1.price * 2}, with_account: true)

      payload = %{"user_id" => user.user_id, "items" => products}
      post(conn, Routes.order_path(conn, :create), order: payload)
      conn = post(conn, Routes.order_path(conn, :create), order: payload)

      assert %{"error" => "products_already_purchased"} = json_response(conn, 400)
    end

    test "returns 400 when balance is insufficient", %{conn: conn} do
      product1 = Fixtures.product_fixture()
      products = [product1.id]
      user = Fixtures.user_fixture(%{balance: 0}, with_account: true)

      payload = %{"user_id" => user.user_id, "items" => products}
      conn = post(conn, Routes.order_path(conn, :create), order: payload)

      assert %{"error" => "insufficient_balance"} = json_response(conn, 400)
    end

    test "returns 400 when product id is invalid", %{conn: conn} do
      products = ["invalid product id"]
      user = Fixtures.user_fixture(%{balance: 0}, with_account: true)

      payload = %{"user_id" => user.user_id, "items" => products}
      conn = post(conn, Routes.order_path(conn, :create), order: payload)

      assert %{"error" => "invalid_product_ids"} = json_response(conn, 400)
    end

    #    test "renders errors when data is invalid", %{conn: conn, user: user} do
    #      conn = post(conn, Routes.order_path(conn, :create), order: %{"user_id" => user.id})
    #
    #      assert json_response(conn, 422)["errors"] != %{}
    #    end
  end
end
