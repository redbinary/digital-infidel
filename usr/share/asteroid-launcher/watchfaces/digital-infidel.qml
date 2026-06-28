/****************************************************************
 * digital-infidel.qml
 *
 * Assets:
 *		/usr/share/fonts/FUTURA MEDIUM BT.TTF
 *		/usr/share/asteroid-launcher/watchfaces/weathericons-outline.js
 *
 *	(C) Ophelion 2026 - Patrick Griffin	<github.com/redbinary>
 *										<ophelion.com>
 ****************************************************************/
/*
 * some portions [most] of step counting pulled from digital-weather-hrm-steps.qml
 *	see info below...
 *
 *
 * Copyright (C) 2025 - Jozef Mlich <github.com/jmlich>
 *               2023 - Timo Könnecke <github.com/eLtMosen>
 *               2022 - Darrel Griët <dgriet@gmail.com>
 *               2022 - Ed Beroset <github.com/beroset>
 *               2017 - Florent Revest <revestflo@gmail.com>
 * All rights reserved.
 *
 * You may use this file under the terms of BSD license as follows:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the author nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import QtQuick 2.15
import Nemo.Configuration 1.0
import Nemo.Mce 1.0
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import org.nemomobile.lipstick 0.1

import QtGraphicalEffects 1.15
import "weathericons-outline.js" as WeatherIcons

Item {
    id: root
    anchors.fill: parent
	
	readonly property bool useWidget_weather: true
	readonly property bool useWidget_battery: true
	readonly property bool useWidget_notifications: true
	readonly property bool useWidget_steps: false

	readonly property bool useTwelveHour: use12H.value

    property string timeString: ""
    property string dateString: ""

    readonly property real s: Math.min(width, height)

    readonly property string white: "#ffffff"
    readonly property string black: "#000000"
    readonly property color batteryGreen: Qt.rgba(0, 216 / 255, 32 / 255, 0.50)
    readonly property string warningRed: "#ff1237"

	readonly property int notificationCount: notificationRepeater.count
	
    readonly property bool batteryCharging: batteryChargeState.value === MceBatteryState.Charging
	
    property int steps: 0
    property bool stepsAvailable: false

    function twoDigits(n) {
        return n < 10 ? "0" + n : "" + n
    }

   function refreshClock() {
		var now = wallClock.time
		var h24 = now.getHours()
		var m = now.getMinutes()
		var h = h24

		if (root.useTwelveHour) {
			h = h24 % 12

			if (h === 0)
				h = 12

			timeString = h + ":" + twoDigits(m)
		} else {
			timeString = twoDigits(h24) + ":" + twoDigits(m)
		}

		dateString = now.toLocaleString(Qt.locale(), "ddd, MMM d")
	}

    function clampBattery() {
        var p = Number(batteryLevel.percent)

        if (isNaN(p))
            return 0

        return Math.max(0, Math.min(100, Math.round(p)))
    }

    function kelvinToTempString(k) {
        var tempK = Number(k)

        if (isNaN(tempK) || tempK <= 1)
            return "--°"

        var c = Math.round(tempK - 273.15)

        if (useFahrenheit.value)
            return Math.round((c * 9 / 5) + 32) + "°"

        return c + "°"
    }

    FontLoader {
        id: futuraFont
        source: "../../fonts/FUTURA MEDIUM BT.TTF"
    }

    MceBatteryLevel {
        id: batteryLevel
    }

    MceBatteryState {
        id: batteryChargeState
    }

    NotificationListModel {
        id: notificationModel
    }

    ConfigurationValue {
        id: useFahrenheit
        key: "/org/asteroidos/settings/use-fahrenheit"
        defaultValue: false
    }

    ConfigurationValue {
        id: weatherTimestamp
        key: "/org/asteroidos/weather/timestamp-day0"
        defaultValue: 0
    }

    ConfigurationValue {
        id: weatherId
        key: "/org/asteroidos/weather/day0/id"
        defaultValue: 0
    }

    ConfigurationValue {
        id: weatherMaxTemp
        key: "/org/asteroidos/weather/day0/max-temp"
        defaultValue: 0
    }
	
	ConfigurationValue {
		id: weatherCurrentTemp
		key: "/org/asteroidos/weather/current-temp"
		defaultValue: 0
	}

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            root.refreshClock()
            bellCanvas.requestPaint()
            chargingBolt.requestPaint()
        }
    }

    Connections {
        target: wallClock

        function onTimeChanged() {
            root.refreshClock()
        }
    }
	
    Item {
        id: face
        width: root.s
        height: root.s
        anchors.centerIn: parent

        /*
         * Weather widget — top-left
         */
		Loader {
			id: weatherWidgetLoader
			anchors.fill: parent
			active: root.useWidget_weather
			sourceComponent: weatherComponent
		}
		
		Component {
			id: weatherComponent
			
			Item {
				anchors.fill: parent
				
				Item {
					id: weatherWidget
					width: face.width * 0.48
					height: face.height * 0.165
					x: face.width * 0.070
					y: face.height * 0.075
					visible: weatherTimestamp.value > 0 || weatherMaxTemp.value > 0

					Icon {
						id: weatherPicture
						width: parent.height * 1.05
						height: width
						anchors.left: parent.left
						anchors.verticalCenter: parent.verticalCenter
						visible: weatherTimestamp.value > 0 || weatherMaxTemp.value > 0

						name: WeatherIcons.getIconName(String(weatherId.value))
					}

					ColorOverlay {
						anchors.fill: weatherPicture
						source: weatherPicture
						color: root.white
						visible: weatherPicture.visible
					}

					/*Text {
						anchors.left: weatherPicture.right
						anchors.leftMargin: face.width * 0.012
						anchors.verticalCenter: weatherPicture.verticalCenter
						text: root.kelvinToTempString(weatherCurrentTemp.value)
						color: root.white
						font.family: futuraFont.name
						font.pixelSize: face.width * 0.08
						font.bold: false
					}*/
				}
			}
		}

        /*
         * Battery widget — top-right
         */
		Loader {
			id: batteryWidgetLoader
			anchors.fill: parent
			active: root.useWidget_battery
			sourceComponent: batteryComponent
		}
		
		Component {
			id: batteryComponent
			
			Item {
				anchors.fill: parent
				
				Item {
					id: batteryWidget
					width: face.width * 0.15
					height: face.height * 0.08
					x: face.width * 0.805
					y: face.height * 0.092

					readonly property int percent: root.clampBattery()

					Rectangle {
						id: batteryOuter
						anchors.left: parent.left
						anchors.verticalCenter: parent.verticalCenter
						width: parent.width * 0.86
						height: parent.height
						radius: height * 0.18
						color: "transparent"
						border.color: root.white
						border.width: Math.max(2, face.width * 0.006)
					}

					Rectangle {
						id: batteryFill
						x: batteryOuter.x + batteryOuter.border.width * 1.5
						y: batteryOuter.y + batteryOuter.border.width * 1.5
						height: batteryOuter.height - batteryOuter.border.width * 3
						width: Math.max(0, (batteryOuter.width - batteryOuter.border.width * 3) * batteryWidget.percent / 100)
						radius: height * 0.10
						color: batteryWidget.percent <= 20 ? root.warningRed : root.batteryGreen
					}

					Rectangle {
						id: batteryNub
						width: parent.width * 0.06
						height: parent.height * 0.48
						radius: width / 2
						color: root.white
						anchors.left: batteryOuter.right
						anchors.leftMargin: face.width * 0.006
						anchors.verticalCenter: batteryOuter.verticalCenter
					}

					Text {
						anchors.fill: batteryOuter
						visible: !root.batteryCharging
						text: batteryWidget.percent
						color: root.white
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						font.family: futuraFont.name
						font.pixelSize: parent.height * 0.80
						font.bold: false
					}

					Canvas {
						id: chargingBolt
						anchors.fill: batteryOuter
						visible: root.batteryCharging
						antialiasing: true
						smooth: true

						onPaint: {
							var ctx = getContext("2d")
							ctx.reset()
							ctx.clearRect(0, 0, width, height)

							ctx.fillStyle = root.white

							ctx.beginPath()
							ctx.moveTo(width * 0.56, height * 0.14)
							ctx.lineTo(width * 0.34, height * 0.55)
							ctx.lineTo(width * 0.50, height * 0.55)
							ctx.lineTo(width * 0.41, height * 0.88)
							ctx.lineTo(width * 0.68, height * 0.43)
							ctx.lineTo(width * 0.51, height * 0.43)
							ctx.closePath()
							ctx.fill()
						}
					}
				}
			}
		}

        /*
         * Time — center, not bold
         */
        Text {
            id: timeText
            width: parent.width
            y: parent.height * 0.385
            text: root.timeString
            color: root.white
            horizontalAlignment: Text.AlignHCenter
            font.family: futuraFont.name
            font.pixelSize: parent.width * 0.235
            font.bold: false
            renderType: Text.NativeRendering
        }

        /*
         * Date — directly above time, not bold
         */
        Text {
            id: dateText
            width: parent.width
            anchors.bottom: timeText.top
            anchors.bottomMargin: parent.height * 0.010
            text: root.dateString
            color: root.white
            horizontalAlignment: Text.AlignHCenter
            font.family: futuraFont.name
            font.pixelSize: parent.width * 0.070
            font.bold: false
        }
		
		/*
		 * Bridge C++ NotificationListModel row count into a QML count.
		 * Do not use notificationModel.count directly.
		 */
		Item {
			id: notificationCounterBridge
			width: 0
			height: 0
			visible: false

			Repeater {
				id: notificationRepeater
				model: notificationModel

				delegate: Item {
					width: 0
					height: 0
					visible: false
				}
			}
		}

        /*
         * Notification bell — bottom-left, hidden when count is zero
         */
		Loader {
			id: notificationWidgetLoader
			anchors.fill: parent
			active: root.useWidget_notifications
			sourceComponent: notificationComponent
		}
		
		Component {
			id: notificationComponent
			
			Item {
				id: notificationWidget
				visible: root.notificationCount > 0
				width: face.width * 0.18
				height: width
				x: face.width * 0.07
				y: face.height * 0.795

				Canvas {
					id: bellCanvas
					anchors.fill: parent
					antialiasing: true
					smooth: true

					onPaint: {
						var ctx = getContext("2d")

						ctx.reset()
						ctx.clearRect(0, 0, width, height)

						ctx.strokeStyle = root.white
						ctx.fillStyle = root.white
						ctx.lineWidth = width * 0.070
						ctx.lineCap = "round"
						ctx.lineJoin = "round"

						ctx.beginPath()
						ctx.moveTo(width * 0.23, height * 0.72)
						ctx.quadraticCurveTo(width * 0.33, height * 0.60,
											 width * 0.33, height * 0.45)
						ctx.quadraticCurveTo(width * 0.33, height * 0.23,
											 width * 0.50, height * 0.20)
						ctx.quadraticCurveTo(width * 0.67, height * 0.23,
											 width * 0.67, height * 0.45)
						ctx.quadraticCurveTo(width * 0.67, height * 0.60,
											 width * 0.77, height * 0.72)
						ctx.lineTo(width * 0.23, height * 0.72)
						ctx.stroke()

						ctx.beginPath()
						ctx.arc(width * 0.50, height * 0.15, width * 0.045, 0, Math.PI * 2)
						ctx.fill()

						ctx.beginPath()
						ctx.moveTo(width * 0.43, height * 0.83)
						ctx.quadraticCurveTo(width * 0.50, height * 0.92,
											 width * 0.57, height * 0.83)
						ctx.stroke()
					}
				}

				Rectangle {
					id: notificationBadge
					visible: root.notificationCount > 0
					width: notificationWidget.width * 0.5
					height: width
					radius: width / 2
					color: root.warningRed
					x: notificationWidget.width * 0.62
					y: notificationWidget.height * 0.06

					Text {
						anchors.centerIn: parent
						text: root.notificationCount > 99 ? "99+" : root.notificationCount
						
						color: root.white
						font.family: futuraFont.name
						font.bold: false
						font.pixelSize: parent.height * 0.8
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
					}
				}
			}
		}
		
		/*
		 * Step count — bottom-right [pulled mostly from digital-weather-hrm-steps.qml]
		 * ...but doesn't work on my Sparrow
		 */
		Loader {
			id: stepsWidgetLoader
			anchors.fill: parent
			active: root.useWidget_steps
			sourceComponent: stepsWidgetComponent
		}
		
		Component {
			id: stepsWidgetComponent
			
			Item {
				anchors.fill: parent
			
				Item {
					id: stepsWidget
					
					width: face.width * 0.335
					height: face.height * 0.105
					x: face.width * 0.590
					y: face.height * 0.800
					opacity: root.stepsAvailable ? 1.0 : 0.3
					
					ConfigurationValue {
						id: stepCount
						key: "/org/asteroidos/health/step-count"
						defaultValue: 0
						onValueChanged: {
							root.steps = stepCount.value
							root.stepsAvailable = stepCount.value > 0
						}
					}

					Icon {
						id: stepsIcon
						
						width: parent.height * 2
						height: width
						anchors.left: parent.left
						anchors.verticalCenter: parent.verticalCenter

						name: "ios-walk"
					}

					ColorOverlay {
						anchors.fill: stepsIcon
						source: stepsIcon
						color: root.white
					}

					Text {
						anchors.left: stepsIcon.right
						anchors.leftMargin: face.width * 0.012
						anchors.right: parent.right
						anchors.verticalCenter: stepsIcon.verticalCenter

						text: root.stepsAvailable ? root.steps : "--"
						color: root.white

						horizontalAlignment: Text.AlignRight
						verticalAlignment: Text.AlignVCenter

						font.family: futuraFont.name
						font.pixelSize: face.width * 0.070
						font.bold: false
					}
				}
			}
		}
    }
}