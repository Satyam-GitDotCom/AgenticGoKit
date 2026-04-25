package main

import (
	"context"
	"fmt"
	"time"

	agk "github.com/agenticgokit/agenticgokit/v1beta"
)

func main() {
	agent, err := agk.NewBuilder("simple-agent").
		WithConfig(&agk.Config{
			Name: "Simple Agent",
			LLM: agk.LLMConfig{
				Provider: "ollama",
				Model:    "qwen2.5-coder:7b",
			},
			Timeout: 30 * time.Second,
		}).Build()
	if err != nil {
		panic(err)
	}

	prompt := "What is the capital of France?"
	response, err := agent.Run(context.Background(), prompt)
	if err != nil {
		panic(err)
	}

	fmt.Println("Response:", response)
}
