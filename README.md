Languages: [English](#english) | [中文](#chinese) | [Español](#español)

# English

<div align="center">
  <img src="assets/logo.svg" alt="LLMCal Logo" width="200">
</div>

# LLMCal - AI-Powered Calendar Event Creator for PopClip

LLMCal is a powerful PopClip extension that uses AI to convert selected text into calendar events. It understands natural language descriptions and automatically creates events with proper titles, times, locations, meeting links, and reminders.

## Features

- 🤖 **AI-Powered**: Uses Claude AI to understand natural language event descriptions
- ⚡️ **Quick Creation**: Create calendar events with a single click
- 🌐 **Meeting Links**: Automatically extracts and adds meeting URLs (Zoom, Teams, Google Meet, etc.)
- 📍 **Location Support**: Handles both physical and virtual meeting locations
- ⏰ **Smart Reminders**: Sets up event alerts based on text descriptions
- 🔄 **Recurring Events**: Supports various recurring event patterns
- 👥 **Attendees**: Automatically adds event participants from email addresses in the text
- 🌍 **Time Zones**: Understands and handles different time zones in event descriptions

## Installation

1. Download the latest release (`LLMCal.popclipext.zip`)
2. Double-click the downloaded file to install it in PopClip
3. When prompted, click "Install Extension"
4. Open PopClip's preferences and click on the LLMCal extension settings
5. Enter your Anthropic API key (Get one from [https://console.anthropic.com/](https://console.anthropic.com/))

## Usage

1. Select any text that describes an event, for example:
   - "Team meeting tomorrow at 2pm for 1 hour"
   - "Weekly standup every Monday at 9:30am, 30 minutes, Zoom link: https://zoom.us/j/123"
   - "Lunch with John next Friday at noon at Starbucks downtown"
2. Click the calendar icon in the PopClip menu
3. The event will be automatically created in your calendar with all relevant details

## Example Inputs

```
"Product demo next Tuesday 3pm with client@example.com, 1 hour on Zoom https://zoom.us/j/123, remind me 15 minutes before"

"Monthly team review on the last Friday of each month, 2pm-4pm, Conference Room A, reminder 1 day before"

"Weekly 1:1 with manager every Thursday 10am PST (my time 1pm EST), 30 minutes, Teams link: https://teams.microsoft.com/l/123"
```

## Requirements

- macOS 10.15 or later
- PopClip 2022.5 or later
- Anthropic API key
- Calendar.app access permission
- Internet connection

## Privacy & Security

- Your API key is stored securely in PopClip's settings
- No event data is stored or transmitted except to create the calendar event
- All natural language processing is done through Claude AI
- The extension only requires necessary permissions: text selection and calendar access

## Troubleshooting

If you encounter any issues:
1. Make sure your Anthropic API key is correctly entered in the extension settings
2. Check that you've granted calendar access permissions to PopClip
3. Ensure your text selection includes all necessary event details
4. Verify your internet connection

## Support

For issues, feature requests, or contributions, please visit the [GitHub repository](https://github.com/cafferychen777/LLMCal).

## License

This project is licensed under the GNU Affero General Public License Version 3 (AGPLv3) with Commons Clause - see the [LICENSE](LICENSE) file for details. This license ensures that the software remains open source while protecting against commercial exploitation. Any modifications or derivative works must also be released under the same license terms.

# Chinese

<div align="center">
  <img src="assets/logo.svg" alt="LLMCal Logo" width="200">
</div>

# LLMCal - 基于 AI 的 PopClip 日历事件创建工具

LLMCal 是一个强大的 PopClip 扩展，使用 AI 将选定的文本转换为日历事件。它能理解自然语言描述，并自动创建包含适当标题、时间、地点、会议链接和提醒的事件。

## 特点

- 🤖 **AI 驱动**：使用 Claude AI 理解自然语言事件描述
- ⚡️ **快速创建**：一键创建日历事件
- 🌐 **会议链接**：自动提取并添加会议 URL（Zoom、Teams、Google Meet 等）
- 📍 **位置支持**：处理实体和虚拟会议地点
- ⏰ **智能提醒**：根据文本描述设置事件提醒
- 🔄 **重复事件**：支持各种重复事件模式
- 👥 **参与者**：自动从文本中的电子邮件地址添加事件参与者
- 🌍 **时区**：理解并处理事件描述中的不同时区

## 安装

1. 下载最新版本（`LLMCal.popclipext.zip`）
2. 双击下载的文件以在 PopClip 中安装
3. 出现提示时，点击"安装扩展"
4. 打开 PopClip 的偏好设置并点击 LLMCal 扩展设置
5. 输入你的 Anthropic API 密钥（从 [https://console.anthropic.com/](https://console.anthropic.com/) 获取）

## 使用方法

1. 选择任何描述事件的文本，例如：
   - "明天下午2点开一小时的团队会议"
   - "每周一上午9:30的站会，30分钟，Zoom链接：https://zoom.us/j/123"
   - "下周五中午和约翰在市中心星巴克吃午饭"
2. 点击 PopClip 菜单中的日历图标
3. 事件将自动创建在你的日历中，包含所有相关详细信息

## 输入示例

```
"下周二下午3点与 client@example.com 进行产品演示，1小时，Zoom会议 https://zoom.us/j/123，提前15分钟提醒"

"每月最后一个周五下午2点到4点的月度团队回顾，会议室A，提前1天提醒"

"每周四上午10点PST（我的时间是EST下午1点）与经理进行30分钟的一对一会议，Teams链接：https://teams.microsoft.com/l/123"
```

## 系统要求

- macOS 10.15 或更高版本
- PopClip 2022.5 或更高版本
- Anthropic API 密钥
- Calendar.app 访问权限
- 互联网连接

## 隐私与安全

- 你的 API 密钥安全存储在 PopClip 的设置中
- 除了创建日历事件外，不存储或传输任何事件数据
- 所有自然语言处理通过 Claude AI 完成
- 扩展仅需要必要的权限：文本选择和日历访问

## 故障排除

如果遇到任何问题：
1. 确保在扩展设置中正确输入了 Anthropic API 密钥
2. 检查是否已授予 PopClip 日历访问权限
3. 确保你的文本选择包含所有必要的事件详细信息
4. 验证你的互联网连接

## 支持

如有问题、功能请求或贡献，请访问 [GitHub 仓库](https://github.com/cafferychen777/LLMCal)。

## 许可证

本项目采用带有 Commons Clause 的 GNU Affero 通用公共许可证第3版 (AGPLv3) 授权 - 详见 [LICENSE](LICENSE) 文件。该许可证确保软件保持开源的同时防止商业利用。任何修改或衍生作品也必须在相同的许可条款下发布。

# Español

<div align="center">
  <img src="assets/logo.svg" alt="LLMCal Logo" width="200">
</div>

# LLMCal - Creador de Eventos de Calendario Impulsado por IA para PopClip

LLMCal es una potente extensión de PopClip que utiliza IA para convertir texto seleccionado en eventos de calendario. Comprende descripciones en lenguaje natural y crea automáticamente eventos con títulos, horarios, ubicaciones, enlaces de reunión y recordatorios apropiados.

## Características

- 🤖 **Impulsado por IA**: Utiliza Claude AI para comprender descripciones de eventos en lenguaje natural
- ⚡️ **Creación Rápida**: Crea eventos de calendario con un solo clic
- 🌐 **Enlaces de Reunión**: Extrae y añade automáticamente URLs de reuniones (Zoom, Teams, Google Meet, etc.)
- 📍 **Soporte de Ubicación**: Maneja ubicaciones de reuniones tanto físicas como virtuales
- ⏰ **Recordatorios Inteligentes**: Configura alertas de eventos basadas en descripciones de texto
- 🔄 **Eventos Recurrentes**: Soporta varios patrones de eventos recurrentes
- 👥 **Participantes**: Añade automáticamente participantes del evento desde direcciones de correo electrónico en el texto
- 🌍 **Zonas Horarias**: Comprende y maneja diferentes zonas horarias en las descripciones de eventos

## Instalación

1. Descarga la última versión (`LLMCal.popclipext.zip`)
2. Haz doble clic en el archivo descargado para instalarlo en PopClip
3. Cuando se te solicite, haz clic en "Instalar Extensión"
4. Abre las preferencias de PopClip y haz clic en la configuración de la extensión LLMCal
5. Ingresa tu clave API de Anthropic (Obtén una en [https://console.anthropic.com/](https://console.anthropic.com/))

## Uso

1. Selecciona cualquier texto que describa un evento, por ejemplo:
   - "Reunión de equipo mañana a las 2pm por 1 hora"
   - "Reunión semanal todos los lunes a las 9:30am, 30 minutos, enlace de Zoom: https://zoom.us/j/123"
   - "Almuerzo con Juan el próximo viernes al mediodía en el Starbucks del centro"
2. Haz clic en el icono del calendario en el menú de PopClip
3. El evento se creará automáticamente en tu calendario con todos los detalles relevantes

## Ejemplos de Entrada

```
"Demostración de producto el próximo martes a las 3pm con client@example.com, 1 hora en Zoom https://zoom.us/j/123, recordarme 15 minutos antes"

"Revisión mensual del equipo el último viernes de cada mes, 2pm-4pm, Sala de Conferencias A, recordatorio 1 día antes"

"Reunión semanal 1:1 con el gerente todos los jueves 10am PST (mi hora 1pm EST), 30 minutos, enlace de Teams: https://teams.microsoft.com/l/123"
```

## Requisitos

- macOS 10.15 o posterior
- PopClip 2022.5 o posterior
- Clave API de Anthropic
- Permiso de acceso a Calendar.app
- Conexión a Internet

## Privacidad y Seguridad

- Tu clave API se almacena de forma segura en la configuración de PopClip
- No se almacena ni transmite ningún dato de eventos excepto para crear el evento del calendario
- Todo el procesamiento del lenguaje natural se realiza a través de Claude AI
- La extensión solo requiere los permisos necesarios: selección de texto y acceso al calendario

## Solución de Problemas

Si encuentras algún problema:
1. Asegúrate de que tu clave API de Anthropic esté correctamente ingresada en la configuración de la extensión
2. Verifica que hayas otorgado permisos de acceso al calendario a PopClip
3. Asegúrate de que tu selección de texto incluya todos los detalles necesarios del evento
4. Verifica tu conexión a Internet

## Soporte

Para problemas, solicitudes de funciones o contribuciones, visita el [Repositorio de GitHub](https://github.com/cafferychen777/LLMCal).

## Licencia

Este proyecto está licenciado bajo la Licencia Pública General de GNU Affero Versión 3 (AGPLv3) con Cláusula Commons - consulta el archivo [LICENSE](LICENSE) para más detalles. Esta licencia asegura que el software permanezca de código abierto mientras protege contra la explotación comercial. Cualquier modificación o trabajo derivado también debe ser publicado bajo los mismos términos de licencia.
