defmodule Meadow.Application.Caches do
  @moduledoc """
  Cache specs for Meadow.Application
  """
  require Cachex.Spec

  def specs do
    [
      cache_spec(:global_cache, Meadow.Cache),
      cache_spec(
        :coded_term_cache,
        Meadow.Cache.CodedTerms,
        expiration: Cachex.Spec.expiration(default: :timer.hours(6)),
        stats: true
      ),
      cache_spec(
        :controlled_term_cache,
        Meadow.Cache.ControlledTerms,
        expiration: Cachex.Spec.expiration(default: :timer.hours(6)),
        stats: true
      ),
      cache_spec(
        :preservation_check_job_cache,
        Meadow.Cache.PreservationChecks,
        expiration: Cachex.Spec.expiration(default: :timer.hours(6)),
        stats: true
      ),
      cache_spec(
        :user_cache,
        Meadow.Cache.Users,
        expiration: Cachex.Spec.expiration(default: :timer.minutes(20)),
        stats: true
      ),
      cache_spec(
        :aws_credentials_cache,
        Meadow.Cache.AWS.Credentials,
        expiration: Cachex.Spec.expiration(default: :timer.hours(6)),
        stats: true
      )
    ]
  end

  def specs(:prod), do: specs()

  def specs(_) do
    [cache_spec(:ark_storage, Meadow.Utils.ArkClient.MockServer.Cache) | specs()]
  end

  defp cache_spec(id, name, args \\ []) do
    %{
      id: id,
      start: {Cachex, :start_link, [name, args]},
      type: :supervisor
    }
  end
end
