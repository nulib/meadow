defmodule MeadowAI do
  @moduledoc """
  MeadowAI - AI-powered metadata generation for the Meadow application.

  This module provides a natural language interface to Claude, equipped with
  specialized tools for metadata generation and analysis of Meadow content.
  """

  alias MeadowAI.MetadataAgent

  @doc """
  Send a natural language query to Claude with optional context.

  Claude will intelligently choose which tools to use based on your request.
  Available tools include keyword generation, description creation, and content analysis.

  ## Parameters
  - prompt: Natural language query (required)
  - opts: Keyword list of options (optional)
    - :context - Map containing contextual information like works, collections, etc.
    - :timeout - Request timeout in milliseconds (default: 30_000)

  ## Examples

      # Extract keywords from content
      iex> MeadowAI.query("Extract keywords from this research paper",
      ...>   context: %{works: [%{title: "AI in Healthcare", content: "Machine learning applications..."}]})
      {:ok, "Based on the content, the main keywords are: machine learning, healthcare, AI, applications, medical"}

      # Generate descriptions
      iex> MeadowAI.query("Create a description for this work",
      ...>   context: %{works: [%{title: "Data Analysis", content: "Statistical methods..."}]})
      {:ok, "This work focuses on statistical methods for data analysis..."}

      # General analysis
      iex> MeadowAI.query("What are the main themes across these works?",
      ...>   context: %{works: [%{title: "Work 1"}, %{title: "Work 2"}]})
      {:ok, "The main themes across these works include..."}

  ## Returns
  - `{:ok, response}` - Claude's response string
  - `{:error, reason}` - Error information
  """
  def query(prompt, opts \\ []) when is_binary(prompt) do
    MetadataAgent.query(prompt, opts)
  end

  @doc """
  Gets the current status of the MetadataAgent.

  ## Examples

      iex> MeadowAI.status()
      {:ok, %{
        python_initialized: true,
        startup_time: ~U[2024-01-01 12:00:00Z],
        request_count: 42,
        uptime_seconds: 3600
      }}

  ## Returns
  - `{:ok, status_map}` - Current agent status information
  - `{:error, reason}` - Error if agent is not available
  """
  def status do
    MetadataAgent.status()
  end
end
