defmodule SQNSTest do
  use SQNS.TestCase
  import ExUnit.CaptureLog
  alias SQNS

  describe "queues" do
    test "create missing queue" do
      assert(
        capture_log(fn ->
          assert(
            SQNS.Queues.create_queue("sqns_test_queue") ==
              "http://sqs.us-east-1.goaws.com:4100/100010001000/sqns_test_queue"
          )
        end) =~ "Creating Queue: sqns_test_queue"
      )
    end

    test "create existing queue" do
      SQNS.Queues.create_queue("sqns_test_queue")

      assert(
        capture_log(fn ->
          assert(SQNS.Queues.create_queue("sqns_test_queue") == :noop)
        end) =~ "Queue sqns_test_queue already exists"
      )
    end
  end

  describe "topics" do
    test "create missing topic" do
      assert(
        capture_log(fn ->
          assert(
            SQNS.Topics.create_topic("sqns_test_topic") ==
              "arn:aws:sns:us-east-1:100010001000:sqns_test_topic"
          )
        end) =~ "Creating Topic: sqns_test_topic"
      )
    end

    test "create existing topic" do
      SQNS.Topics.create_topic("sqns_test_topic")

      assert(
        capture_log(fn ->
          assert(SQNS.Topics.create_topic("sqns_test_topic") == :noop)
        end) =~ "Topic sqns_test_topic already exists"
      )
    end
  end

  describe "subscriptions" do
    setup do
      SQNS.Queues.create_queue("sqns_test_queue")
      SQNS.Topics.create_topic("sqns_test_topic")
      :ok
    end

    test "create missing subscription" do
      assert(
        capture_log(fn ->
          assert(
            SQNS.Subscriptions.create_subscription({"sqns_test_queue", "sqns_test_topic", nil}) ==
              {"arn:aws:sns:us-east-1:100010001000:sqns_test_topic",
               "arn:aws:sqs:us-east-1:100010001000:sqns_test_queue", %{}}
          )
        end) =~ "Creating Subscription: sqns_test_topic → sqns_test_queue"
      )
    end

    test "create existing subscription" do
      SQNS.Subscriptions.create_subscription({"sqns_test_queue", "sqns_test_topic", nil})

      assert(
        capture_log(fn ->
          assert(
            SQNS.Subscriptions.create_subscription({"sqns_test_queue", "sqns_test_topic", nil}) ==
              :noop
          )
        end) =~ "Subscription sqns_test_topic → sqns_test_queue already exists"
      )
    end
  end

  describe "specs" do
    test "create all queues, topics, and subscriptions based on a spec", context do
      SQNS.setup([
        :a,
        b: [a: [status: :ok]],
        c: [:a, :b]
      ])

      expected_queues = ~w(a b c)
      expected_topics = ~w(a b c)

      expected_subscriptions = [
        {"a", "c", %{}},
        {"b", "c", %{}},
        {"a", "b", %{"status" => ["ok"]}}
      ]

      with actual_queues <- queue_names(context) |> Enum.sort() do
        assert(actual_queues == expected_queues)
      end

      with actual_topics <- topic_names(context) |> Enum.sort() do
        assert(actual_topics == expected_topics)
      end

      with actual_subscriptions <- subscriptions(context) do
        assert(
          expected_subscriptions
          |> Enum.all?(fn sub -> sub in actual_subscriptions end)
        )

        assert(actual_subscriptions -- expected_subscriptions == [])
      end
    end
  end
end
