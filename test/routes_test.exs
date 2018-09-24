defmodule RoutesTest do
  use ExUnit.Case
  doctest Routes

  test "locations are created correctly" do
    assert(
      match?(
        {:error, _},
        Location.new(%Coordinate{lat: 1, lon: 2}, "Caffee", :fancy_coffee)
      ),
      "It should not create location when wrong types are provided!"
    )

    assert(
      match?(
        {:ok, %Location{}},
        Location.new(%Coordinate{lat: 42.3, lon: 44.3}, "Caffee", :landmark)
      )
    )
  end

  test "calculates distance correctly" do
    {:ok, location1} = Location.new(%Coordinate{lat: 1, lon: 2}, "Caffee", :cafe)
    {:ok, location2} = Location.new(%Coordinate{lat: 3, lon: 4}, "Shop", :shop)
    dist1 = Location.distance(location1, location2)

    {:ok, location1} = Location.new(%Coordinate{lat: -1, lon: -2}, "Caffee", :cafe)
    {:ok, location2} = Location.new(%Coordinate{lat: -3, lon: -4}, "Shop", :shop)
    dist2 = Location.distance(location1, location2)

    {:ok, location1} = Location.new(%Coordinate{lat: 1, lon: 2}, "Caffee", :cafe)
    {:ok, location2} = Location.new(%Coordinate{lat: -3, lon: -4}, "Shop", :shop)
    dist3 = Location.distance(location1, location2)

    assert(Float.floor(dist1, 2) == 2.82, "Does not calculate correctly distance!")
    assert(Float.floor(dist2, 2) == 2.82, "Does not calculate correctly distance!")
    assert(Float.floor(dist3, 2) == 7.21, "Does not calculate correctly distance!")
  end

  test "calculates a route length correctly" do
    {:ok, location1} = Location.new(%Coordinate{lat: 1, lon: 2}, "Caffee", :cafe)
    {:ok, location2} = Location.new(%Coordinate{lat: 3, lon: 4}, "Shop", :shop)
    {:ok, location3} = Location.new(%Coordinate{lat: -1, lon: -2}, "Sevastopol", :landmark)
    {:ok, location4} = Location.new(%Coordinate{lat: -3, lon: -4}, "Big Shop", :shop)

    route = %Route{
      locations: [location1, location2, location3, location4],
      name: "A simple route"
    }

    assert(Float.floor(Route.length(route), 2) == 12.86)
    assert(Route.length(%Route{locations: []}) == 0)
    assert(Route.length(%Route{locations: [location1]}) == 0)
  end

  test "calculates the best route correctly" do
    {:ok, location1} = Location.new(%Coordinate{lat: 1, lon: 2}, "Caffee", :cafe)
    {:ok, location2} = Location.new(%Coordinate{lat: 3, lon: 4}, "Shop", :shop)
    {:ok, location3} = Location.new(%Coordinate{lat: -1, lon: -2}, "Sevastopol", :landmark)
    {:ok, location4} = Location.new(%Coordinate{lat: -3, lon: -4}, "Big Shop", :shop)

    route1 = %Route{locations: [location1, location2, location3, location4], name: "Route 1"}
    route2 = %Route{locations: [location1, location3, location4], name: "Route 2"}
    route3 = %Route{locations: [location3, location4], name: "Route 3"}

    assert(match?({:ok, ^route2}, Route.best(route1, route2)))
    assert(match?({:error, _}, Route.best(route1, route3)))
  end

  test "prints correctly" do
    {:ok, location1} = Location.new(%Coordinate{lat: 1, lon: 2}, "Caffee", :cafe)
    {:ok, location2} = Location.new(%Coordinate{lat: 3, lon: 4}, "Shop", :shop)
    {:ok, location3} = Location.new(%Coordinate{lat: -1, lon: -2}, "Sevastopol", :landmark)
    {:ok, location4} = Location.new(%Coordinate{lat: -3, lon: -4}, "Big Shop", :shop)

    route1 = %Route{locations: [location1, location2, location3, location4], name: "Route 1"}
    expected_result = "Caffee -> Shop -> Sevastopol -> Big Shop"

    assert(Route.print(route1) == expected_result)
  end

  test "it adds a route" do
    :sys.replace_state(Routes, fn _state -> [] end)

    {:ok, location1} = Location.new(%Coordinate{lat: 1, lon: 2}, "Caffee", :cafe)
    {:ok, location2} = Location.new(%Coordinate{lat: 3, lon: 4}, "Shop", :shop)
    {:ok, location3} = Location.new(%Coordinate{lat: -1, lon: -2}, "Sevastopol", :landmark)
    {:ok, location4} = Location.new(%Coordinate{lat: -3, lon: -4}, "Big Shop", :shop)

    route1 = %Route{locations: [location1, location2, location3, location4], name: "Route 1"}
    Routes.add(route1)

    assert(:sys.get_state(Routes) == [route1])
  end

  test "it removes a route correctly" do
    :sys.replace_state(Routes, fn _state -> [] end)

    {:ok, location1} = Location.new(%Coordinate{lat: 1, lon: 2}, "Caffee", :cafe)
    {:ok, location2} = Location.new(%Coordinate{lat: 3, lon: 4}, "Shop", :shop)
    {:ok, location3} = Location.new(%Coordinate{lat: -1, lon: -2}, "Sevastopol", :landmark)
    {:ok, location4} = Location.new(%Coordinate{lat: -3, lon: -4}, "Big Shop", :shop)

    route1 = %Route{locations: [location1, location2, location3, location4], name: "Route 1"}
    route2 = %Route{locations: [location1, location3, location4], name: "Route 2"}
    route3 = %Route{locations: [location1, location2], name: "Route 3"}
    Routes.add(route1)
    Routes.add(route2)
    Routes.add(route3)

    Routes.destroyed("Shop")

    assert(:sys.get_state(Routes) == [route2])
  end

  test "it calculates the best route correctly" do
    :sys.replace_state(Routes, fn _state -> [] end)

    {:ok, location1} = Location.new(%Coordinate{lat: 1, lon: 2}, "Caffee", :cafe)
    {:ok, location2} = Location.new(%Coordinate{lat: 3, lon: 4}, "Shop", :shop)
    {:ok, location3} = Location.new(%Coordinate{lat: -1, lon: -2}, "Sevastopol", :landmark)
    {:ok, location4} = Location.new(%Coordinate{lat: -3, lon: -4}, "Big Shop", :shop)

    route1 = %Route{locations: [location1, location2, location3, location4], name: "Route 1"}
    route2 = %Route{locations: [location1, location3, location4], name: "Route 2"}
    route3 = %Route{locations: [location1, location2], name: "Route 3"}
    Routes.add(route1)
    Routes.add(route2)
    Routes.add(route3)

    assert(match?({:ok, ^route2}, Routes.best("Caffee", "Big Shop")))
    assert(match?({:ok, ^route2}, Routes.best("Big Shop", "Caffee")))
    assert(match?({:error, _}, Routes.best("Sevastopol", "Caffee")))
    assert(match?({:error, _}, Routes.best("Caffee", "Invalid destination")))
  end

  test "prints all routes correctly" do
    :sys.replace_state(Routes, fn _state -> [] end)

    {:ok, location1} = Location.new(%Coordinate{lat: 1, lon: 2}, "Caffee", :cafe)
    {:ok, location2} = Location.new(%Coordinate{lat: 3, lon: 4}, "Shop", :shop)
    {:ok, location3} = Location.new(%Coordinate{lat: -1, lon: -2}, "Sevastopol", :landmark)
    {:ok, location4} = Location.new(%Coordinate{lat: -3, lon: -4}, "Big Shop", :shop)

    route1 = %Route{locations: [location1, location2, location3, location4], name: "Route 1"}
    route3 = %Route{locations: [location1, location2], name: "Route 3"}
    assert(Routes.print_all() == "")
    Routes.add(route1)

    assert(Routes.print_all() == "Caffee -> Shop -> Sevastopol -> Big Shop")

    Routes.add(route3)

    assert(Routes.print_all() == "Caffee -> Shop\nCaffee -> Shop -> Sevastopol -> Big Shop")
  end
end
