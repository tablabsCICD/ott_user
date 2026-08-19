/*
   Licensed to the Apache Software Foundation (ASF) under one or more
   contributor license agreements.  See the NOTICE file distributed with
   this work for additional information regarding copyright ownership.
   The ASF licenses this file to You under the Apache License, Version 2.0
   (the "License"); you may not use this file except in compliance with
   the License.  You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
var showControllersOnly = false;
var seriesFilter = "";
var filtersOnlySampleSeries = true;

/*
 * Add header in statistics table to group metrics by category
 * format
 *
 */
function summaryTableHeader(header) {
    var newRow = header.insertRow(-1);
    newRow.className = "tablesorter-no-sort";
    var cell = document.createElement('th');
    cell.setAttribute("data-sorter", false);
    cell.colSpan = 1;
    cell.innerHTML = "Requests";
    newRow.appendChild(cell);

    cell = document.createElement('th');
    cell.setAttribute("data-sorter", false);
    cell.colSpan = 3;
    cell.innerHTML = "Executions";
    newRow.appendChild(cell);

    cell = document.createElement('th');
    cell.setAttribute("data-sorter", false);
    cell.colSpan = 7;
    cell.innerHTML = "Response Times (ms)";
    newRow.appendChild(cell);

    cell = document.createElement('th');
    cell.setAttribute("data-sorter", false);
    cell.colSpan = 1;
    cell.innerHTML = "Throughput";
    newRow.appendChild(cell);

    cell = document.createElement('th');
    cell.setAttribute("data-sorter", false);
    cell.colSpan = 2;
    cell.innerHTML = "Network (KB/sec)";
    newRow.appendChild(cell);
}

/*
 * Populates the table identified by id parameter with the specified data and
 * format
 *
 */
function createTable(table, info, formatter, defaultSorts, seriesIndex, headerCreator) {
    var tableRef = table[0];

    // Create header and populate it with data.titles array
    var header = tableRef.createTHead();

    // Call callback is available
    if(headerCreator) {
        headerCreator(header);
    }

    var newRow = header.insertRow(-1);
    for (var index = 0; index < info.titles.length; index++) {
        var cell = document.createElement('th');
        cell.innerHTML = info.titles[index];
        newRow.appendChild(cell);
    }

    var tBody;

    // Create overall body if defined
    if(info.overall){
        tBody = document.createElement('tbody');
        tBody.className = "tablesorter-no-sort";
        tableRef.appendChild(tBody);
        var newRow = tBody.insertRow(-1);
        var data = info.overall.data;
        for(var index=0;index < data.length; index++){
            var cell = newRow.insertCell(-1);
            cell.innerHTML = formatter ? formatter(index, data[index]): data[index];
        }
    }

    // Create regular body
    tBody = document.createElement('tbody');
    tableRef.appendChild(tBody);

    var regexp;
    if(seriesFilter) {
        regexp = new RegExp(seriesFilter, 'i');
    }
    // Populate body with data.items array
    for(var index=0; index < info.items.length; index++){
        var item = info.items[index];
        if((!regexp || filtersOnlySampleSeries && !info.supportsControllersDiscrimination || regexp.test(item.data[seriesIndex]))
                &&
                (!showControllersOnly || !info.supportsControllersDiscrimination || item.isController)){
            if(item.data.length > 0) {
                var newRow = tBody.insertRow(-1);
                for(var col=0; col < item.data.length; col++){
                    var cell = newRow.insertCell(-1);
                    cell.innerHTML = formatter ? formatter(col, item.data[col]) : item.data[col];
                }
            }
        }
    }

    // Add support of columns sort
    table.tablesorter({sortList : defaultSorts});
}

$(document).ready(function() {

    // Customize table sorter default options
    $.extend( $.tablesorter.defaults, {
        theme: 'blue',
        cssInfoBlock: "tablesorter-no-sort",
        widthFixed: true,
        widgets: ['zebra']
    });

    var data = {"OkPercent": 16.666666666666668, "KoPercent": 83.33333333333333};
    var dataset = [
        {
            "label" : "FAIL",
            "data" : data.KoPercent,
            "color" : "#FF6347"
        },
        {
            "label" : "PASS",
            "data" : data.OkPercent,
            "color" : "#9ACD32"
        }];
    $.plot($("#flot-requests-summary"), dataset, {
        series : {
            pie : {
                show : true,
                radius : 1,
                label : {
                    show : true,
                    radius : 3 / 4,
                    formatter : function(label, series) {
                        return '<div style="font-size:8pt;text-align:center;padding:2px;color:white;">'
                            + label
                            + '<br/>'
                            + Math.round10(series.percent, -2)
                            + '%</div>';
                    },
                    background : {
                        opacity : 0.5,
                        color : '#000'
                    }
                }
            }
        },
        legend : {
            show : true
        }
    });

    // Creates APDEX table
    createTable($("#apdexTable"), {"supportsControllersDiscrimination": true, "overall": {"data": [0.16666666666666666, 500, 1500, "Total"], "isController": false}, "titles": ["Apdex", "T (Toleration threshold)", "F (Frustration threshold)", "Label"], "items": [{"data": [1.0, 500, 1500, "02 - Public Latest Content"], "isController": false}, {"data": [0.0, 500, 1500, "01 - Search Content By Key"], "isController": false}, {"data": [0.0, 500, 1500, "01 - Get User Profile"], "isController": false}, {"data": [0.0, 500, 1500, "01 - Movie or Content Details"], "isController": false}, {"data": [0.0, 500, 1500, "02 - Series Details"], "isController": false}, {"data": [0.0, 500, 1500, "01 - Get User Push Notifications"], "isController": false}, {"data": [0.0, 500, 1500, "02 - Verify OTP"], "isController": false}, {"data": [0.0, 500, 1500, "01 - Request Signed Playback URL"], "isController": false}, {"data": [1.0, 500, 1500, "03 - Public Top Ten Content"], "isController": false}, {"data": [0.0, 500, 1500, "02 - Continue Watching List"], "isController": false}, {"data": [0.0, 500, 1500, "01 - Send OTP"], "isController": false}, {"data": [0.0, 500, 1500, "01 - Dashboard Filter Type3"], "isController": false}]}, function(index, item){
        switch(index){
            case 0:
                item = item.toFixed(3);
                break;
            case 1:
            case 2:
                item = formatDuration(item);
                break;
        }
        return item;
    }, [[0, 0]], 3);

    // Create statistics table
    createTable($("#statisticsTable"), {"supportsControllersDiscrimination": true, "overall": {"data": ["Total", 12, 10, 83.33333333333333, 45.08333333333334, 11, 357, 14.5, 259.2000000000004, 357.0, 357.0, 1.0251153254741159, 1.141491943234239, 0.23342062831026825], "isController": false}, "titles": ["Label", "#Samples", "FAIL", "Error %", "Average", "Min", "Max", "Median", "90th pct", "95th pct", "99th pct", "Transactions/s", "Received", "Sent"], "items": [{"data": ["02 - Public Latest Content", 1, 0, 0.0, 25.0, 25, 25, 25.0, 25.0, 25.0, 25.0, 40.0, 119.1796875, 8.7109375], "isController": false}, {"data": ["01 - Search Content By Key", 1, 1, 100.0, 12.0, 12, 12, 12.0, 12.0, 12.0, 12.0, 83.33333333333333, 62.33723958333333, 18.147786458333332], "isController": false}, {"data": ["01 - Get User Profile", 1, 1, 100.0, 12.0, 12, 12, 12.0, 12.0, 12.0, 12.0, 83.33333333333333, 62.33723958333333, 14.485677083333332], "isController": false}, {"data": ["01 - Movie or Content Details", 1, 1, 100.0, 11.0, 11, 11, 11.0, 11.0, 11.0, 11.0, 90.9090909090909, 68.00426136363637, 19.264914772727273], "isController": false}, {"data": ["02 - Series Details", 1, 1, 100.0, 12.0, 12, 12, 12.0, 12.0, 12.0, 12.0, 83.33333333333333, 62.33723958333333, 16.438802083333332], "isController": false}, {"data": ["01 - Get User Push Notifications", 1, 1, 100.0, 31.0, 31, 31, 31.0, 31.0, 31.0, 31.0, 32.25806451612903, 24.130544354838708, 6.741431451612903], "isController": false}, {"data": ["02 - Verify OTP", 1, 1, 100.0, 16.0, 16, 16, 16.0, 16.0, 16.0, 16.0, 62.5, 46.32568359375, 19.95849609375], "isController": false}, {"data": ["01 - Request Signed Playback URL", 1, 1, 100.0, 18.0, 18, 18, 18.0, 18.0, 18.0, 18.0, 55.55555555555555, 41.55815972222223, 20.779079861111114], "isController": false}, {"data": ["03 - Public Top Ten Content", 1, 0, 0.0, 21.0, 21, 21, 21.0, 21.0, 21.0, 21.0, 47.61904761904761, 137.97433035714286, 9.161086309523808], "isController": false}, {"data": ["02 - Continue Watching List", 1, 1, 100.0, 13.0, 13, 13, 13.0, 13.0, 13.0, 13.0, 76.92307692307693, 57.542067307692314, 15.474759615384617], "isController": false}, {"data": ["01 - Send OTP", 1, 1, 100.0, 357.0, 357, 357, 357.0, 357.0, 357.0, 357.0, 2.8011204481792715, 2.1281950280112047, 0.6209515056022409], "isController": false}, {"data": ["01 - Dashboard Filter Type3", 1, 1, 100.0, 13.0, 13, 13, 13.0, 13.0, 13.0, 13.0, 76.92307692307693, 57.542067307692314, 15.099158653846155], "isController": false}]}, function(index, item){
        switch(index){
            // Errors pct
            case 3:
                item = item.toFixed(2) + '%';
                break;
            // Mean
            case 4:
            // Mean
            case 7:
            // Median
            case 8:
            // Percentile 1
            case 9:
            // Percentile 2
            case 10:
            // Percentile 3
            case 11:
            // Throughput
            case 12:
            // Kbytes/s
            case 13:
            // Sent Kbytes/s
                item = item.toFixed(2);
                break;
        }
        return item;
    }, [[0, 0]], 0, summaryTableHeader);

    // Create error table
    createTable($("#errorsTable"), {"supportsControllersDiscrimination": false, "titles": ["Type of error", "Number of errors", "% in errors", "% in all samples"], "items": [{"data": ["500", 2, 20.0, 16.666666666666668], "isController": false}, {"data": ["401", 8, 80.0, 66.66666666666667], "isController": false}]}, function(index, item){
        switch(index){
            case 2:
            case 3:
                item = item.toFixed(2) + '%';
                break;
        }
        return item;
    }, [[1, 1]]);

        // Create top5 errors by sampler
    createTable($("#top5ErrorsBySamplerTable"), {"supportsControllersDiscrimination": false, "overall": {"data": ["Total", 12, 10, "401", 8, "500", 2, "", "", "", "", "", ""], "isController": false}, "titles": ["Sample", "#Samples", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors"], "items": [{"data": [], "isController": false}, {"data": ["01 - Search Content By Key", 1, 1, "401", 1, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["01 - Get User Profile", 1, 1, "401", 1, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["01 - Movie or Content Details", 1, 1, "401", 1, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["02 - Series Details", 1, 1, "401", 1, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["01 - Get User Push Notifications", 1, 1, "401", 1, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["02 - Verify OTP", 1, 1, "500", 1, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["01 - Request Signed Playback URL", 1, 1, "401", 1, "", "", "", "", "", "", "", ""], "isController": false}, {"data": [], "isController": false}, {"data": ["02 - Continue Watching List", 1, 1, "401", 1, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["01 - Send OTP", 1, 1, "500", 1, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["01 - Dashboard Filter Type3", 1, 1, "401", 1, "", "", "", "", "", "", "", ""], "isController": false}]}, function(index, item){
        return item;
    }, [[0, 0]], 0);

});
