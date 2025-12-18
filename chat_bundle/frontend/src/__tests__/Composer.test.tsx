/**
 * @jest-environment jsdom
 */
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import Composer from "../components/Composer";
import axios from "axios";

jest.mock("axios");
const mockedAxios = axios as jest.Mocked<typeof axios>;

describe("Composer", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("renders and sends a message", async () => {
    mockedAxios.post.mockResolvedValue({ data: { id: "m_1", sender: "u1", body: "hello" } });

    const onSent = jest.fn();
    render(<Composer chatId="chat_u1_u2" currentUser="u1" onSent={onSent} />);

    const input = screen.getByPlaceholderText("Type a message") as HTMLInputElement;
    fireEvent.change(input, { target: { value: "hello" } });

    const button = screen.getByText("Send");
    fireEvent.click(button);

    await waitFor(() => {
      expect(mockedAxios.post).toHaveBeenCalledWith(
        "http://localhost:8000/chats/chat_u1_u2/send",
        { sender: "u1", body: "hello", lang: "yoruba" }
      );
    });
  });

  it("does not send empty messages", async () => {
    render(<Composer chatId="chat_u1_u2" currentUser="u1" />);

    const button = screen.getByText("Send");
    fireEvent.click(button);

    await waitFor(() => {
      expect(mockedAxios.post).not.toHaveBeenCalled();
    });
  });
});

