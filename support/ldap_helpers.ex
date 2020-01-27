defmodule Meadow.LdapHelpers do
  def add_entry(connection, entry, attributes) do
    entry = to_charlist(entry)

    attributes =
      case Enum.find(attributes, fn x -> x == {'distinguishedName', entry} end) do
        nil -> [{'distinguishedName', [entry]} | attributes]
        _ -> attributes
      end

    :eldap.add(connection, entry, attributes)
  end

  def destroy_entry(connection, entry) do
    empty_tree(connection, entry)
    :eldap.delete(connection, to_charlist(entry))
  end

  def empty_tree(connection, parent_dn) do
    case Exldap.search(connection,
           base: parent_dn,
           scope: :eldap.wholeSubtree(),
           filter: Exldap.equalityMatch("objectClass", "top")
         ) do
      {:ok, children} ->
        with base <- to_charlist(parent_dn) do
          children
          |> Enum.each(fn
            %Exldap.Entry{object_name: ^base} -> :noop
            leaf -> :eldap.delete(connection, leaf.object_name)
          end)
        end

      {:error, :noSuchObject} ->
        :noop
    end
  end

  def add_membership(connection, parent_dn, child_dn) do
    :eldap.modify(connection, to_charlist(parent_dn), [
      :eldap.mod_add('member', [to_charlist(child_dn)])
    ])
  end

  def ou_attributes(rdn) do
    [
      {'objectClass', ['organizationalUnit', 'top']},
      {'ou', [to_charlist(rdn)]},
      {'name', [to_charlist(rdn)]}
    ]
  end

  def group_attributes(rdn) do
    [
      {'objectClass', ['group', 'top']},
      {'groupType', ['4']},
      {'cn', [rdn]},
      {'description', [to_charlist("Group #{rdn}")]},
      {'displayName', [to_charlist("Group #{rdn}")]}
    ]
  end

  def people_attributes(username) do
    [
      {'objectClass', ['user', 'person', 'organizationalPerson', 'top']},
      {'sn', [to_charlist(username)]},
      {'uid', [to_charlist(username)]},
      {'mail', [to_charlist("#{username}@library.northwestern.edu")]},
      {'displayName', [to_charlist("User #{username}")]}
    ]
  end
end
