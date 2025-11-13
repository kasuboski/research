# /// script
# dependencies = [
#   "mlx-lm",
# ]
# ///

from mlx_lm import generate, load


def main():
    print("Loading model...")
    model, tokenizer = load("ncls-p/VibeThinker-1.5B-mlx-8Bit")
    print("Model loaded! Type 'exit' or 'quit' to end the conversation.\n")

    messages = []

    while True:
        # Get user input
        try:
            user_input = input("You: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\n\nGoodbye!")
            break

        # Check for exit commands
        if user_input.lower() in ["exit", "quit", "q"]:
            print("Goodbye!")
            break

        # Skip empty inputs
        if not user_input:
            continue

        # Add user message to history
        messages.append({"role": "user", "content": user_input})

        # Prepare prompt with chat template if available
        if (
            hasattr(tokenizer, "apply_chat_template")
            and tokenizer.chat_template is not None
        ):
            prompt = tokenizer.apply_chat_template(
                messages, tokenize=False, add_generation_prompt=True
            )
        else:
            # Fallback: just use the user input
            prompt = user_input

        # Generate response
        print("Assistant: ", end="", flush=True)
        response = generate(
            model,
            tokenizer,
            prompt=prompt,
            max_tokens=2048,  # Allow longer responses for thinking models
            verbose=False,
        )
        print(response)
        print()  # Extra newline for readability

        # Add assistant response to history
        messages.append({"role": "assistant", "content": response})


if __name__ == "__main__":
    main()
