require "./test/test_helper"
require "./lib/invoice"

class InvoiceTest < Minitest::Test

  def setup
    @hash = {:created_at => "2013-08-05 00:00:00 -0600",
      :customer_id => "1",
      :id => "4",
      :merchant_id => "12335938",
      :status => "pending",
      :updated_at => "2014-06-06 00:00:00 -0600"}
  end

  def test_invoice_returns_the_id
    assert_equal 4, Invoice.new(@hash).id
  end

  def test_it_can_find_the_cutomer_id
    assert_equal 1, Invoice.new(@hash).customer_id
  end

  def test_it_can_find_the_merchant_id
    assert_equal 12335938, Invoice.new(@hash).merchant_id
  end

  def test_it_can_find_the_status
    assert_equal :pending, Invoice.new(@hash).status
  end

  def test_it_can_find_the_created_date
    time = Time.strptime("2013-08-05", "%Y-%m-%d")
    assert_equal time, Invoice.new(@hash).created_at
  end

  def test_it_can_find_the_updated_date
    time = Time.strptime("2014-06-06", "%Y-%m-%d")
    assert_equal time, Invoice.new(@hash).updated_at
  end

  def test_it_can_find_the_merchant_related_to_this_invoice
    mock_invoice_repo = Minitest::Mock.new
    mock_invoice_repo.expect(:find_merchant_by_id, "merchant", [234567])
    data = {id: "1", customer_id: "123456", merchant_id: "234567", status: "pending", created_at: "2009-12-09", updated_at: "2009-12-09"}
    invoice = Invoice.new(data , mock_invoice_repo)
    assert_equal "merchant", invoice.merchant
    assert mock_invoice_repo.verify
  end
end
