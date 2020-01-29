defmodule MeadowWeb.Resolvers.Accounts do
  @moduledoc """
  Absinthe resolver for User and Group Management related functionality
  """
  defmodule Entry do
    @moduledoc """
    Temporary struct for mocked data
    """
    defstruct [:id, :name, :type]
  end

  # alias Meadow.Accounts.Ldap

  def me(_, _, %{context: %{current_user: user}}) do
    {:ok, user}
  end

  def me(_, _, _) do
    {:ok, nil}
  end

  def list_roles(_, _, _) do
    {:ok,
     [
       %Entry{
         id: "CN=Administrators,OU=Meadow,DC=library,DC=northwestern,DC=edu",
         name: "Administrators",
         type: "group"
       },
       %Entry{
         id: "CN=Managers,OU=Meadow,DC=library,DC=northwestern,DC=edu",
         name: "Managers",
         type: "group"
       },
       %Entry{
         id: "CN=Editors,OU=Meadow,DC=library,DC=northwestern,DC=edu",
         name: "Editors",
         type: "group"
       },
       %Entry{
         id: "CN=Users,OU=Meadow,DC=library,DC=northwestern,DC=edu",
         name: "Users",
         type: "group"
       }
     ]}
  end

  def role_members(_, %{id: _id}, _) do
    {:ok,
     [
       %Entry{
         id: "CN=DevOps,OU=Meadow,DC=library,DC=northwestern,DC=edu",
         name: "DevOps",
         type: "group"
       },
       %Entry{
         id: "CN=Curators,OU=Meadow,DC=library,DC=northwestern,DC=edu",
         name: "Curators",
         type: "group"
       },
       %Entry{
         id: "CN=Temp Workers,OU=Meadow,DC=library,DC=northwestern,DC=edu",
         name: "Temp Workers",
         type: "group"
       },
       %Entry{
         id: "CN=jad123,OU=Meadow,DC=library,DC=northwestern,DC=edu",
         name: "Jane Doe",
         type: "user"
       }
     ]}
  end

  def group_members(_, %{id: _id}, _) do
    {:ok,
     [
       %Entry{
         id: "CN=dld978,OU=Meadow,DC=library,DC=northwestern,DC=edu",
         name: "Darryl Duggan",
         type: "user"
       },
       %Entry{
         id: "CN=mtp654,OU=Meadow,DC=library,DC=northwestern,DC=edu",
         name: "Myah Parks",
         type: "user"
       },
       %Entry{
         id: "CN=RDC Staff,OU=Meadow,DC=library,DC=northwestern,DC=edu",
         name: "RDC Staff",
         type: "group"
       },
       %Entry{
         id: "CN=jad123,OU=Meadow,DC=library,DC=northwestern,DC=edu",
         name: "Jane Doe",
         type: "user"
       }
     ]}
  end

  def add_group_to_role(_, %{group_id: _group_id, role_id: _role_id}, _) do
    {:ok,
     %Entry{
       id: "CN=Editors,OU=Meadow,DC=library,DC=northwestern,DC=edu",
       name: "Editors",
       type: "group"
     }}
  end
end
