defmodule CueWeb.CueLive.Members do
  use CueWeb, :live_view

  alias Cue.Groups
  alias Cue.Accounts

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    cue = Groups.get_cue!(id)
    current_user = socket.assigns.current_user

    if can_manage_members?(current_user, cue) do
      members = Groups.list_cue_users(cue)

      {:ok,
       socket
       |> assign(:cue, cue)
       |> assign(:members, members)
       |> assign(:user_role, Groups.get_user_role(current_user, cue))
       |> assign(:is_creator, cue.creator_id == current_user.id)
       |> assign(:user_email, "")}
    else
      {:ok,
       socket
       |> put_flash(:error, "You don't have permission to manage members.")
       |> redirect(to: ~p"/cues/#{id}")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Members - #{socket.assigns.cue.name}")
    |> assign(:user_email, nil)
  end

  defp apply_action(socket, :add, _params) do
    socket
    |> assign(:page_title, "Add Member - #{socket.assigns.cue.name}")
    |> assign(:user_email, "")
    |> assign(:live_action, :add)
  end

  @impl true
  def handle_event("remove_member", %{"user-id" => user_id}, socket) do
    cue = socket.assigns.cue
    current_user = socket.assigns.current_user

    user_to_remove = Accounts.get_user!(user_id)

    # Prevent removing creator or yourself if you're admin
    cond do
      user_to_remove.id == cue.creator_id ->
        {:noreply, put_flash(socket, :error, "Cannot remove the creator of the cue.")}

      user_to_remove.id == current_user.id && Groups.get_user_role(current_user, cue) == "admin" ->
        {:noreply, put_flash(socket, :error, "You cannot remove yourself as an admin.")}

      true ->
        case Groups.remove_user_from_cue(user_to_remove, cue) do
          {:ok, _} ->
            members = Groups.list_cue_users(cue)

            {:noreply,
             socket
             |> assign(:members, members)
             |> put_flash(:info, "Member removed successfully.")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to remove member.")}
        end
    end
  end

  @impl true
  def handle_event("change_role", %{"user-id" => user_id, "role" => role}, socket) do
    cue = socket.assigns.cue
    current_user = socket.assigns.current_user

    user_to_update = Accounts.get_user!(user_id)

    # Prevent changing creator's role or your own role if you're admin
    cond do
      user_to_update.id == cue.creator_id ->
        {:noreply, put_flash(socket, :error, "Cannot change the creator's role.")}

      user_to_update.id == current_user.id && role != "admin" ->
        {:noreply, put_flash(socket, :error, "You cannot demote yourself as an admin.")}

      true ->
        case Groups.update_user_role(user_to_update, cue, role) do
          {:ok, _} ->
            members = Groups.list_cue_users(cue)

            {:noreply,
             socket
             |> assign(:members, members)
             |> put_flash(:info, "Role updated successfully.")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to update role.")}
        end
    end
  end

  @impl true
  def handle_event("add_member", %{"user" => %{"email" => email, "role" => role}}, socket) do
    cue = socket.assigns.cue

    case Accounts.get_user_by_email(email) do
      nil ->
        {:noreply, put_flash(socket, :error, "User not found.")}

      user ->
        if Groups.is_member?(user, cue) do
          {:noreply, put_flash(socket, :error, "User is already a member.")}
        else
          case Groups.add_user_to_cue(user, cue, %{role: role}) do
            {:ok, _} ->
              {:noreply,
               socket
               |> put_flash(:info, "Member added successfully.")
               |> redirect(to: ~p"/cues/#{cue.id}/members")}

            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Failed to add member.")}
          end
        end
    end
  end

  defp can_manage_members?(user, cue) do
    user.id == cue.creator_id || Groups.get_user_role(user, cue) == "admin"
  end
end
