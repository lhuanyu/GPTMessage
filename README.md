# GPTMessage
A SwiftUI app demonstrating ChatGPT with an iMessage-like UI.

This is what the app looks like on iOS:
<p float="left">
  <img src="screenshot.PNG" width="350" />
  <img src="screenshot1.PNG" width="350" /> 
</p>

## Usage

Set your OpenAI API key in the AppConfiguration.

```swift

class AppConfiguration: ObservableObject {
        
    @AppStorage("configuration.key") var key = "OpenAI API Key"
    
}

```
