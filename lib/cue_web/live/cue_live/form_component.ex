defmodule CueWeb.CueLive.FormComponent do
  use CueWeb, :live_component

  alias Cue.Groups

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="cue-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" required />
        <.input field={@form[:description]} type="textarea" label="Description" />

        <:actions>
          <.button phx-disable-with="Saving...">Save Cue</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{cue: cue} = assigns, socket) do
    changeset = Groups.change_cue(cue)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"cue_group" => cue_params}, socket) do
    changeset =
      socket.assigns.cue
      |> Groups.change_cue(cue_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"cue_group" => cue_params}, socket) do
    save_cue(socket, socket.assigns.action, cue_params)
  end

  defp save_cue(socket, :edit, cue_params) do
    case Groups.update_cue(socket.assigns.cue, cue_params) do
      {:ok, cue} ->
        notify_parent({:saved, cue})

        {:noreply,
         socket
         |> put_flash(:info, "Cue updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_cue(socket, :new, cue_params) do
    # Add creator_id to the params
    cue_params = Map.put(cue_params, "creator_id", socket.assigns.current_user.id)

    case Groups.create_cue(cue_params) do
      {:ok, cue} ->
        # Automatically add the creator as an admin
        Groups.add_user_to_cue(socket.assigns.current_user, cue, %{role: "admin"})

        notify_parent({:saved, cue})

        {:noreply,
         socket
         |> put_flash(:info, "Cue created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
