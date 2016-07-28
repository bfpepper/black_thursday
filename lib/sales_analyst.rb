class SalesAnalyst

  attr_reader :merchant_repo,
              :item_repo

  def initialize(sales_engine)
    @sales_engine = sales_engine
    @merchant_repo = @sales_engine.merchants
    @item_repo = @sales_engine.items
  end

  def average_items_per_merchant
    total_merchants = merchant_repo.all.count
    total_items = item_repo.all.count
    (total_items.to_f / total_merchants).round(2)
  end

  def average_items_per_merchant_standard_deviation
    average = average_items_per_merchant
    deviation = sum_deviation(average)
    denominator = @merchant_repo.all.count - 1
    Math.sqrt(deviation / denominator).round(2)
  end

  def sum_deviation(average)
    @merchant_repo.all.reduce(0) do |deviation, merchant|
      deviation += (merchant.items.count - average) ** 2
    end
  end

  def merchants_with_high_item_count
    average = average_items_per_merchant
    standard_deviation = average_items_per_merchant_standard_deviation
    @merchant_repo.all.select do |merchant|
      merchant.items.count > (standard_deviation + average)
    end
  end

  def average_item_price_for_merchant(merchant_id)
    items = @item_repo.find_all_by_merchant_id(merchant_id)
    item_unit_price = items.reduce(0) do |total, item|
      total += item.unit_price
    end
    (item_unit_price / items.count).floor(2)
  end

  def average_average_price_per_merchant
    sum = @merchant_repo.all.reduce(0) do |total, merchant|
      total += average_item_price_for_merchant(merchant.id)
    end
    (sum / @merchant_repo.all.count).floor(2)
  end

  def golden_items
      average = average_item_price
      deviation = standard_deviation_in_items_price(average)
      @item_repo.all.select do |item|
        item.unit_price > average + deviation * 2
      end
  end

  def average_item_price
    sum = @item_repo.all.reduce(0) do |total, item|
      total += item.unit_price
    end
    sum / @item_repo.all.count
  end

  def standard_deviation_in_items_price(average)
    diviation = @item_repo.all.reduce(0) do |total, item|
      total += (item.unit_price - average) ** 2
    end
    item_count = @item_repo.all.count
    Math.sqrt(diviation / (item_count - 1))
  end
end
