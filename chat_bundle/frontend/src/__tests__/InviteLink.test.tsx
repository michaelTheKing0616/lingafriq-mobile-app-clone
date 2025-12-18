/**
 * @jest-environment jsdom
 */
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import InviteLink from "../components/InviteLink";
import axios from "axios";

jest.mock("axios");
const mockedAxios = axios as jest.Mocked<typeof axios>;

describe("InviteLink", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("creates an invite and shows link", async () => {
    mockedAxios.post.mockResolvedValue({
      data: {
        link: "polie://invite/testtoken",
        created_by: "u1",
        purpose: "add_contact",
        scope: ["add_contact"],
        uses: 1,
        expires_at: new Date().toISOString()
      }
    });

    render(<InviteLink currentUser="u1" />);

    const createBtn = screen.getByText("Create Invite");
    fireEvent.click(createBtn);

    await waitFor(() => {
      expect(mockedAxios.post).toHaveBeenCalledWith(
        "http://localhost:8000/invites/create",
        expect.objectContaining({
          created_by: "u1",
          purpose: "add_contact"
        })
      );
    });

    await waitFor(() => {
      expect(screen.getByDisplayValue("polie://invite/testtoken")).toBeInTheDocument();
    });
  });

  it("handles errors gracefully", async () => {
    mockedAxios.post.mockRejectedValue({
      response: { data: { detail: "Failed to create invite" } }
    });

    render(<InviteLink currentUser="u1" />);

    const createBtn = screen.getByText("Create Invite");
    fireEvent.click(createBtn);

    await waitFor(() => {
      expect(screen.getByText(/Failed to create invite/i)).toBeInTheDocument();
    });
  });
});

