require "pry"

class SalesAnalyst

  attr_reader :se

  def initialize(sales_engine)
    @se = sales_engine
  end
  #items per merchant
  def average_items_per_merchant
    total_merchants = se.merchants.all.count
    total_items = se.items.all.count
    (total_items.to_f / total_merchants).round(2)
  end

  def average_items_per_merchant_standard_deviation
    average = average_items_per_merchant
    deviation = sum_deviation(average)
    denominator = se.merchants.all.count - 1
    Math.sqrt(deviation / denominator).round(2)
  end

  def sum_deviation(average)
    se.merchants.all.reduce(0) do |deviation, merchant|
      deviation += (merchant.items.count - average) ** 2
    end
  end

  def merchants_with_high_item_count
    average = average_items_per_merchant
    standard_deviation = average_items_per_merchant_standard_deviation
    se.merchants.all.select do |merchant|
      merchant.items.count > (standard_deviation + average)
    end
  end

  def average_item_price_for_merchant(merchant_id)
    items = se.items.find_all_by_merchant_id(merchant_id)
    item_unit_price = items.reduce(0) do |total, item|
      total += item.unit_price
    end
    (item_unit_price / items.count).round(2)
  end

  def average_average_price_per_merchant
    sum = se.merchants.all.reduce(0) do |total, merchant|
      total += average_item_price_for_merchant(merchant.id)
    end
    (sum / se.merchants.all.count).floor(2)
  end

  #items
  def golden_items
    average = average_item_price
    deviation = standard_deviation_in_items_price(average)
    se.items.all.select do |item|
      item.unit_price > average + deviation * 2
    end
  end

  def average_item_price
    sum = se.items.all.reduce(0) do |total, item|
      total += item.unit_price
    end
    sum / se.items.all.count
  end

  def standard_deviation_in_items_price(average)
    deviation = se.items.all.reduce(0) do |total, item|
      total += (item.unit_price - average) ** 2
    end
    item_count = se.items.all.count
    Math.sqrt(deviation / (item_count - 1))
  end

  #invoices per merchant
  def average_invoices_per_merchant
    invoice_count = se.invoices.all.count
    merchant_count= se.merchants.all.count
    (invoice_count.to_f / merchant_count).round(2)
  end

  def average_invoices_per_merchant_standard_deviation
    average = average_invoices_per_merchant
    deviation  = standard_deviation_in_invoices(average)
    merchants = se.merchants.all.count
    Math.sqrt(deviation/(merchants - 1)).round(2)
  end

  def standard_deviation_in_invoices(average)
    se.merchants.all.reduce(0) do |total, merchant|
      total += (merchant.invoices.count - average) ** 2
    end
  end

  def top_merchants_by_invoice_count
    average = average_invoices_per_merchant
    standard_deviation = average_invoices_per_merchant_standard_deviation
    result = se.merchants.all.select do |merchant|
      merchant.invoices.count > (average + (standard_deviation * 2))
    end
    return result || []
  end

  def bottom_merchants_by_invoice_count
    average = average_invoices_per_merchant
    standard_deviation = average_invoices_per_merchant_standard_deviation
    result = se.merchants.all.select do |merchant|
      merchant.invoices.count <= (average - (standard_deviation * 2))
    end
    result || []
  end

  #invoices by day
  def average_invoices_per_day
    se.invoices.all.count / 7
  end

  def group_invoices_by_day
    se.invoices.all.group_by do |invoice|
      invoice.created_at.strftime("%A")
    end
  end

  def average_invoices_per_day_standard_deviation
    average = average_invoices_per_day
    deviation = deviation_in_invoices_per_day(average)
    Math.sqrt(deviation / 6).round(2)
  end

  def deviation_in_invoices_per_day(average)
    invoices_on_days = group_invoices_by_day
    sum = invoices_on_days.values.reduce(0) do |total, invoices_on_day|
      total += (invoices_on_day.count - average) ** 2
    end
    sum
  end
  def top_days_by_invoice_count
    average = average_invoices_per_day
    standard_deviation = average_invoices_per_day_standard_deviation
    invoices_by_days = group_invoices_by_day
    invoices_by_days.keys.select do |day|
      invoices_by_days[day].count > average + standard_deviation
    end
  end
  def invoice_status(status)
    invoice_count = se.invoices.all.count
    invoices_with_status = se.invoices.find_all_by_status(status).count
    (invoices_with_status.to_f / invoice_count * 100.0).round(2)
  end

  #revenue info
  def revenue_by_merchant(merchant_id)
    merchants_invoices = @se.find_all_invoices_by_merchant_id(merchant_id)
    merchants_invoices.reduce(0) do |revenue, invoice|
      revenue += invoice.total if invoice.is_paid_in_full?
      revenue
    end
  end

  def total_revenue_by_date(date)
    total_invoices = se.invoices.all.select do |invoice|
      invoice.created_at == date
    end
    total_invoices.reduce(0) do |revenue, invoice|
      revenue += invoice.total if invoice.is_paid_in_full?
      revenue
    end
  end

  def top_revenue_earners(threshhold = 20)
    merchants_ranked_by_revenue[0..threshhold - 1]
  end

  def merchants_ranked_by_revenue
    sorted_merchants = se.merchants.all.sort_by do |merchant|
      revenue_by_merchant(merchant.id)
    end
    sorted_merchants.reverse
  end

  def merchants_with_pending_invoices
    se.merchants.all.select do |merchant|
      merchant_invoices = se.invoices.find_all_by_merchant_id(merchant.id)
      merchant_invoices.any? do |invoice|
        not invoice.is_paid_in_full?
      end
    end
  end

  def merchants_with_only_one_item
    se.merchants.all.select do |merchant|
      merchant_items = se.items.find_all_by_merchant_id(merchant.id)
      merchant_items.count == 1
    end
  end

  def merchants_with_only_one_item_registered_in_month(month)
    se.merchants.all.select do |merchant|
      merchant_items = se.items.find_all_by_merchant_id(merchant.id)
      merchant_items.count == 1 && merchant.created_at.strftime("%B") == month
    end
  end

  def most_sold_item_for_merchant(merchant_id)
    paid_invoice_items = paid_invoice_items_for_merchant(merchant_id)
    items_from_invoices = items_in_invoices(paid_invoice_items)
    grouped_items = items_from_invoices.group_by do |item|
      quantity_of_item_over_all_invoices(item, paid_invoice_items)
    end
    grouped_items[grouped_items.keys.max]
  end

  def best_item_for_merchant(merchant_id)
    paid_invoice_items = paid_invoice_items_for_merchant(merchant_id)
    items_from_invoices = items_in_invoices(paid_invoice_items)
    grouped_items = group_quantities(items_from_invoices, paid_invoice_items)
    grouped_items.last
  end

  def group_quantities(items_from_invoices, paid_invoice_items)
    items_from_invoices.sort_by do |item|
      paid_invoice_items.reduce(0) do |revenue, invoice_item|
        if invoice_item.item_id == item.id
          revenue += invoice_item.quantity * invoice_item.unit_price
        end
        revenue
      end
    end
  end

  def items_in_invoices(paid_invoice_items)
    paid_invoice_items.map do |invoice_item|
      invoice_item.item
    end.uniq
  end

  def quantity_of_item_over_all_invoices(item, paid_invoice_items)
    paid_invoice_items.reduce(0) do |total, invoice_item|
      total += invoice_item.quantity if invoice_item.item_id == item.id
      total
    end
  end

  def paid_invoice_items_for_merchant(merchant_id)
    invoices_by_merchant = se.invoices.find_all_by_merchant_id(merchant_id)
    invoices_by_merchant.reduce([]) do |result, invoice|
      if invoice.is_paid_in_full?
        result += se.invoice_items.find_all_by_invoice_id(invoice.id)
      end
      result
    end
  end


  def customer_with_most_returns
    invoices_with_returns = se.invoices.find_all_by_status(:returned)
    customers_with_returns = invoices_with_returns.map do |invoice|
      invoice.customer
    end.uniq

    grouped_customers = customers_with_returns.group_by do |customer|
      invoices_with_returns.reduce(0) do |returns, invoice|
        returns += 1 if invoice.customer_id == customer.id
        returns
      end
    end

    grouped_customers[grouped_customers.keys.max]
  end


end
