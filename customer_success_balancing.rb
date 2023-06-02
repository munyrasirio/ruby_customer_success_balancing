require 'minitest/autorun'
require 'timeout'

def find_customer_score_range(customers)
  customers.minmax_by { |customer| customer[:score] }.map { |customer| customer[:score] }
end

def find_available_css_by_score(css, min_score, max_score)
  available_css = []

  css.each do |customer_success|
    if customer_success[:score] >= min_score
      available_css.push(customer_success)
    end

    break if customer_success[:score] > max_score
  end 

  available_css
end

def assign_customer_to_css(available_css, customers)
  available_css.map do |customer_success|
    assigned_customers = customers.select { |customer| customer[:score] <= customer_success[:score] }
  
    customers = customers.slice(assigned_customers.length, customers.length)
    { id: customer_success[:id], assigned_customers: assigned_customers.length }
  end
end

def find_css_with_more_customers(css)
  css.select { |customer_success| customer_success[:assigned_customers] === css.max_by { |customer_success| customer_success[:assigned_customers] }[:assigned_customers] }
end

class CustomerSuccessBalancing
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success
    @customers = customers
    @away_customer_success = away_customer_success
  end

  def execute
    working_css = @customer_success.reject { |customer_success| @away_customer_success.include?(customer_success[:id]) }
    css_sorted_by_score = working_css.sort_by { |customer_success| customer_success[:score] }
  
    min_customer_score, max_customer_score = find_customer_score_range(@customers)

    available_css = find_available_css_by_score(css_sorted_by_score, min_customer_score, max_customer_score)
   
    customer_sorted_by_score = @customers.sort_by { |customer| customer[:score] }
    css_with_customers = assign_customer_to_css(available_css, customer_sorted_by_score)

    css_with_more_customers = find_css_with_more_customers(css_with_customers)
   
    id = 0
    return id if css_with_customers.empty?

    if css_with_more_customers.length === 1
      id = css_with_more_customers[0][:id]
    end

    id
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10000, 998)),
      [999]
    )
    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 6, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  def test_scenario_eight
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 40, 95, 75]),
      build_scores([90, 70, 20, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end
