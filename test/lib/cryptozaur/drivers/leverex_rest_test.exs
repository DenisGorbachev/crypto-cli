defmodule Cryptozaur.Drivers.LeverexRestTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney, options: [clear_mock: true]
  require OK

  setup_all do
    HTTPoison.start()

    credentials = Application.get_env(:cryptozaur, :leverex, key: "", secret: "")

    {:ok, driver} = Cryptozaur.Drivers.LeverexRest.start_link(Enum.into(credentials, %{}))

    %{driver: driver}
  end

  test "get_info", %{driver: driver} do
    use_cassette "leverex/get_info", match_requests_on: [:query] do
      {:ok, %{"assets" => %{"BTC" => %{"min_confirmation_count" => 3}, "BTC_D" => %{"min_confirmation_count" => 2}, "BTC_T" => %{"min_confirmation_count" => 3}, "ETH" => %{"min_confirmation_count" => 12}, "ETH_D" => %{"min_confirmation_count" => 2}, "PICK_D" => %{"min_confirmation_count" => 2}}, "markets" => %{"BTC:USDT" => %{"amount_precision" => 8, "base" => "BTC", "delisted_at" => nil, "listed_at" => "2018-06-08T12:00:00", "lot_size" => 0.00000001, "maker_fee" => 0.00100000, "price_precision" => 8, "quote" => "USDT", "taker_fee" => 0.00100000, "tick_size" => 0.00000001}, "ETH_D:BTC_D" => %{"amount_precision" => 8, "base" => "ETH_D", "delisted_at" => nil, "listed_at" => "2018-07-27T12:00:00", "lot_size" => 0.00000001, "maker_fee" => 0.00100000, "price_precision" => 8, "quote" => "BTC_D", "taker_fee" => 0.00100000, "tick_size" => 0.00000001}, "ETH_T:BTC_T" => %{"amount_precision" => 8, "base" => "ETH_T", "delisted_at" => nil, "listed_at" => "2018-06-17T12:00:00", "lot_size" => 0.00000001, "maker_fee" => 0.00100000, "price_precision" => 8, "quote" => "BTC_T", "taker_fee" => 0.00100000, "tick_size" => 0.00000001}}}} = Cryptozaur.Drivers.LeverexRest.get_info(driver)
    end
  end

  test "get_balances", %{driver: driver} do
    use_cassette "leverex/get_balances", match_requests_on: [:query] do
      {:ok,
       [
         %{
           "asset" => "BTC_D",
           "available_amount" => 10.0,
           "total_amount" => 10.0
         },
         %{
           "asset" => "ETH_D",
           "available_amount" => 1000.0,
           "total_amount" => 1000.0
         }
       ]} = Cryptozaur.Drivers.LeverexRest.get_balances(driver)
    end
  end

  test "place_order", %{driver: driver} do
    use_cassette "leverex/place_order" do
      {:ok,
       %{
         "external_id" => nil,
         "called_amount" => 1.0,
         "filled_amount" => 0.0
         # LeverEX returns full order; other properties are not shown
       }} = Cryptozaur.Drivers.LeverexRest.place_order(driver, "ETH_D:BTC_D", 1.0, 0.00001)
    end
  end

  test "cancel_order", %{driver: driver} do
    use_cassette "leverex/cancel_order" do
      {:ok,
       %{
         "external_id" => nil,
         "called_amount" => 1.0,
         "filled_amount" => 0.0
       }} = Cryptozaur.Drivers.LeverexRest.cancel_order(driver, "1")
    end
  end

  @tag timeout: 240_000
  test "get_orders", %{driver: driver} do
    # NOTE: use_cassette runs out of memory on large requests
    use_cassette "leverex/get_orders", match_requests_on: [:query] do
      {:ok, orders} = Cryptozaur.Drivers.LeverexRest.get_orders(driver)

      assert [
               %{
                 "called_amount" => 0.00000001,
                 "external_id" => nil,
                 "fee" => 0.00000000,
                 "filled_amount" => 0.00000000,
                 "id" => 1238,
                 "inserted_at" => "2018-07-28T17:55:22.376743",
                 "is_active" => true,
                 "is_cancelled" => false,
                 "limit_price" => 0.00000001,
                 "symbol" => "ETH_D:BTC_D",
                 "trigger_price" => nil,
                 "triggered_at" => "2018-07-28T17:55:22.376485",
                 "updated_at" => "2018-07-28T17:55:22.376750"
               }
               | _
             ] = orders

      assert length(orders) == 1237
    end
  end
end
