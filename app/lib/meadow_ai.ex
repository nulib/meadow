defmodule MeadowAI do
  @moduledoc """
  MeadowAI - AI-powered metadata generation for the Meadow application.

  This module provides a natural language interface to Claude, equipped with
  specialized tools for metadata generation and analysis of Meadow content.

  ## AWS Bedrock Configuration

  To use AWS Bedrock instead of the Anthropic API, set these environment variables:

      # Primary method - Bedrock API key:
      export AWS_BEARER_TOKEN_BEDROCK=your_bedrock_bearer_token
      export AWS_REGION=us-east-1

      # Alternative - AWS Access Keys:
      export CLAUDE_CODE_USE_BEDROCK=1
      export AWS_REGION=us-east-1
      export AWS_ACCESS_KEY_ID=your_access_key
      export AWS_SECRET_ACCESS_KEY=your_secret_key
      # Optional for temporary credentials:
      export AWS_SESSION_TOKEN=your_session_token

      # Optional token limits:
      export CLAUDE_CODE_MAX_OUTPUT_TOKENS=4096
      export MAX_THINKING_TOKENS=1024

  The library will use credentials in this priority order:
  1. AWS_BEARER_TOKEN_BEDROCK (preferred)
  2. AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY
  3. Default AWS credentials (CLI/IAM roles)
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

  @doc """
  Restarts the Python session for the MetadataAgent.

  This can be useful for recovery from Python-related errors or to refresh
  the session state.

  ## Examples

      iex> MeadowAI.restart_session()
      :ok

  ## Returns
  - `:ok` - Session restarted successfully
  - `{:error, reason}` - Error information if restart failed
  """
  def restart_session do
    MetadataAgent.restart_session()
  end

  @doc """
  Hello world function for basic connectivity testing.

  ## Examples

      iex> MeadowAI.hello()
      :world

  """
  def hello do
    :world
  end

  @doc """
  Check current configuration and AWS Bedrock setup.

  ## Examples

      iex> MeadowAI.check_config()
      %{
        bedrock_enabled: true,
        aws_region: "us-east-1",
        aws_credentials_configured: true,
        max_output_tokens: "4096"
      }

  ## Returns
  Map with current configuration status
  """
  def check_config do
    %{
      bedrock_enabled: System.get_env("CLAUDE_CODE_USE_BEDROCK") == "1",
      aws_region: System.get_env("AWS_REGION", "us-east-1"),
      aws_credentials_configured: !!(System.get_env("AWS_ACCESS_KEY_ID") || System.get_env("AWS_PROFILE")),
      max_output_tokens: System.get_env("CLAUDE_CODE_MAX_OUTPUT_TOKENS", "4096"),
      max_thinking_tokens: System.get_env("MAX_THINKING_TOKENS", "1024")
    }
  end

end
