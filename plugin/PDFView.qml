/*
 * Copyright (C) 2013-2014 Jolla Ltd.
 * Contact: Robin Burchell <robin.burchell@jolla.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; version 2 only.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Office.PDF 1.0 as PDF

SilicaFlickable {
    id: base;

    contentWidth: pdfCanvas.width;
    contentHeight: pdfCanvas.height;

    property alias itemWidth: pdfCanvas.width;
    property alias itemHeight: pdfCanvas.height;
    property alias document: pdfCanvas.document;

    property bool scaled: pdfCanvas.width != width;

    signal clicked();
    signal updateSize(real newWidth, real newHeight);

    function clamp(value) {
        if (value < width) {
            return width;
        }

        if (value > width * 2.5) {
            return width * 2.5;
        }

        return value;
    }

    function zoom(amount, center) {
        var oldWidth = pdfCanvas.width;

        pdfCanvas.width = clamp(pdfCanvas.width * amount);

        var realZoom = pdfCanvas.width / oldWidth;
        contentX += (center.x * realZoom) - center.x;
        contentY += (center.y * realZoom) - center.y;
    }

    // Ensure proper zooming level when device is rotated.
    onWidthChanged: pdfCanvas.width = scaled ? clamp(pdfCanvas.width) : width

    PDF.Canvas {
        id: pdfCanvas;

        width: base.width;
        // When not zoomed, device rotation will change width and height,
        // so, we shift content position with changing ratio.
        onHeightChanged: if (!base.scaled) base.contentY *= height / base.contentHeight
        onWidthChanged: if (!base.scaled) base.contentX *= width / base.contentWidth

        spacing: Theme.paddingLarge;
        flickable: base;
        linkColor: Theme.highlightColor;

        PinchArea {
            anchors.fill: parent;
            onPinchUpdated: {
                var newCenter = mapToItem(pdfCanvas, pinch.center.x, pinch.center.y)
                base.zoom(1.0 + (pinch.scale - pinch.previousScale), newCenter);
            }
            onPinchFinished: base.returnToBounds();

            PDF.LinkArea {
                anchors.fill: parent;

                canvas: pdfCanvas;
                onLinkClicked: Qt.openUrlExternally(linkTarget);
                onClicked: base.clicked();
            }
        }
    }

    children: [
        HorizontalScrollDecorator { color: Theme.highlightDimmerColor; },
        VerticalScrollDecorator { color: Theme.highlightDimmerColor; }
    ]

    function goToPage(pageNumber) {
        base.contentY = pdfCanvas.pagePosition( pageNumber );
    }
}
