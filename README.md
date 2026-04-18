# Mantik - MikroTik Management App

Mantik is a modern, responsive Flutter application designed to simplify the remote management and real-time monitoring of MikroTik routers via the RouterOS API. With Mantik, you get an intuitive, user-friendly interface to manage standard ISP operations right from your mobile device.

## Core Features

- **Smart Dashboard**: Instantly view your PPPoE Summary (Total, Active, and Offline clients).
- **Physical Interface Real-time Traffic Monitor**: Visualize `Rx/Tx` live traffic on your main communication interfaces (Ethernet, Bridge, WLAN) beautifully graphed using customized line charts.
- **PPPoE Management (Users & Secrets)**:
  - Add new PPPoE user profiles swiftly.
  - Enable, disable, or delete active/offline users remotely.
- **Simple Queues Management**:
  - View all active queues, target limits, and restrictions in an organized view.
  - **Live Queue Traffic Monitoring**: Tap on any given queue to open a dedicated screen detailing dynamic network metrics (Upload/Download bandwidth in real-time).

## Technical Stack
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Charting Engine**: `fl_chart` for highly optimized, live-updating graphing.
- **MikroTik Integration**: `router_os_client` for rapid and secure communication with RouterOS systems.

## Getting Started
1. Ensure your MikroTik router has the **API service enabled** (`/ip service enable api`).
2. Build and launch this Flutter application.
3. Authenticate securely using your Router's Host IP, API Port (default: 8728), Username, and Password.
4. Manage your core ISP/Home-network operations from the palm of your hand.
