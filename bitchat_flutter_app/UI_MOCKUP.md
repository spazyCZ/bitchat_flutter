# Flutter Implementation Visual Mockup

## Terminal-Style Chat Interface

```
┌─────────────────────────────────────────────────────────────┐
│ bitchat* QuickFox42                    [🔵] 2               │
├─────────────────────────────────────────────────────────────┤
│ Channel: #general                                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ * Welcome to bitchat* QuickFox42                            │
│ * Scanning for peers...                                     │
│ * Mesh networking started                                   │
│ * Peer connected: peer1234                                  │
│                                                             │
│ [12:34:56] <QuickFox42> Hello everyone!                     │
│ [12:35:02] <Alice> Hi there! Welcome to the mesh           │
│ [12:35:15] <Bob (via Alice)> This message was relayed      │
│ [12:35:20] <QuickFox42> /who                               │
│ * Connected peers: Alice, Bob                               │
│ [12:35:25] <Alice> /join #developers                       │
│ * Alice joined channel: #developers                        │
│ [12:35:30] <QuickFox42> /join #developers                  │
│ * Joined channel: #developers                              │
│                                                             │
│                                                             │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ Message #developers...                              [📤]    │
└─────────────────────────────────────────────────────────────┘
                                [👥] <- Peer List FAB
```

## Key UI Elements

### Colors
- **Background**: Black (#000000)
- **Text**: Green (#00FF00) 
- **Timestamps**: Dimmed green (#00FF0080)
- **System messages**: Italic green (#00FF00B3)
- **Own messages**: Cyan (#00FFFF)
- **Other users**: Yellow (#FFFF00)

### Typography
- **Font**: Monospace (terminal style)
- **Sizes**: 12px for messages, 10px for timestamps
- **Weight**: Bold for usernames, normal for content

### Layout Components

#### Header Bar
- App title "bitchat*" + current nickname
- Bluetooth status indicator (🔵 connected, 🔴 disconnected)  
- Connected peer count

#### Channel Bar (when in channel)
- Current channel name display
- Channel status indicators

#### Message Area
- Scrollable message list
- Auto-scroll to bottom for new messages
- Timestamp + sender + content format
- System messages in italics with "*" prefix

#### Input Area
- Message input field with hint text
- Send button (📤)
- Channel-aware placeholder text

#### Floating Action Button
- Peer list button (👥)
- Shows connected peers dialog

### Message Format Examples

```
[HH:MM:SS] <Sender> Message content
[HH:MM:SS] <RelayNode (via OriginalSender)> Relayed message
* System notification message
```

### Dialog Examples

#### Peer List Dialog
```
┌─────────────────────────────────┐
│ Connected Peers                 │
├─────────────────────────────────┤
│ Your ID: peer4321               │
│                                 │
│ • Alice (peer1234)              │
│ • Bob (peer5678)                │
│ • Charlie (peer9012)            │
│                                 │
│                    [Close]      │
└─────────────────────────────────┘
```

### Command Examples
- `/who` → Shows connected peer list
- `/join #channel` → Joins or creates channel
- `/leave` → Leaves current channel  
- `/nick NewName` → Changes nickname
- `/help` → Shows command help

This terminal-style interface maintains the authentic hacker aesthetic of the original Swift app while being touch-friendly for mobile devices.