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
    createTable($("#apdexTable"), {"supportsControllersDiscrimination": true, "overall": {"data": [0.16666666666666666, 500, 1500, "Total"], "isController": false}, "titles": ["Apdex", "T (Toleration threshold)", "F (Frustration threshold)", "Label"], "items": [{"data": [1.0, 500, 1500, "05 - Public Top Ten Content"], "isController": false}, {"data": [0.0, 500, 1500, "11 - Continue Watching List"], "isController": false}, {"data": [0.0, 500, 1500, "12 - Get Push Notifications"], "isController": false}, {"data": [0.0, 500, 1500, "02 - Verify OTP"], "isController": false}, {"data": [0.0, 500, 1500, "03 - Dashboard Filter Type3"], "isController": false}, {"data": [0.0, 500, 1500, "09 - Request Signed Playback URL"], "isController": false}, {"data": [0.0, 500, 1500, "10 - Get User Profile"], "isController": false}, {"data": [0.0, 500, 1500, "06 - Movie Content Details"], "isController": false}, {"data": [0.0, 500, 1500, "07 - Series Details"], "isController": false}, {"data": [0.0, 500, 1500, "01 - Send OTP"], "isController": false}, {"data": [0.0, 500, 1500, "08 - Search Content By Key"], "isController": false}, {"data": [1.0, 500, 1500, "04 - Public Latest Content"], "isController": false}]}, function(index, item){
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
    createTable($("#statisticsTable"), {"supportsControllersDiscrimination": true, "overall": {"data": ["Total", 120, 100, 83.33333333333333, 19.208333333333346, 7, 488, 11.0, 32.900000000000006, 41.89999999999998, 403.7899999999968, 1.8407166523499816, 1.809363950906553, 0.42048271835501294], "isController": false}, "titles": ["Label", "#Samples", "FAIL", "Error %", "Average", "Min", "Max", "Median", "90th pct", "95th pct", "99th pct", "Transactions/s", "Received", "Sent"], "items": [{"data": ["05 - Public Top Ten Content", 10, 0, 0.0, 18.5, 14, 40, 16.0, 37.900000000000006, 40.0, 40.0, 0.18739927289082117, 0.542982072917057, 0.036235406281623625], "isController": false}, {"data": ["11 - Continue Watching List", 10, 10, 100.0, 10.3, 7, 14, 10.0, 13.9, 14.0, 14.0, 0.18739927289082117, 0.14018344046325099, 0.038339987959596714], "isController": false}, {"data": ["12 - Get Push Notifications", 10, 10, 100.0, 9.8, 8, 12, 10.0, 11.9, 12.0, 12.0, 0.18743439796071376, 0.1402097156620183, 0.039353901915579546], "isController": false}, {"data": ["02 - Verify OTP", 10, 10, 100.0, 15.899999999999995, 10, 37, 12.5, 35.800000000000004, 37.0, 37.0, 0.18708723877944286, 0.13867110764999718, 0.058592653785710276], "isController": false}, {"data": ["03 - Dashboard Filter Type3", 10, 10, 100.0, 13.600000000000001, 8, 29, 10.0, 28.5, 29.0, 29.0, 0.18726591760299627, 0.14008368445692884, 0.03694112827715356], "isController": false}, {"data": ["09 - Request Signed Playback URL", 10, 10, 100.0, 12.0, 8, 26, 10.0, 25.200000000000003, 26.0, 26.0, 0.18737469317393993, 0.1401650536828496, 0.07010082515130507], "isController": false}, {"data": ["10 - Get User Profile", 10, 10, 100.0, 9.700000000000001, 8, 11, 9.5, 11.0, 11.0, 11.0, 0.18738171529222178, 0.1401703065564862, 0.0327552021848708], "isController": false}, {"data": ["06 - Movie Content Details", 10, 10, 100.0, 12.5, 8, 28, 10.0, 26.900000000000006, 28.0, 28.0, 0.18745547932366063, 0.14022548550969147, 0.03992582035204139], "isController": false}, {"data": ["07 - Series Details", 10, 10, 100.0, 12.0, 8, 23, 11.0, 22.1, 23.0, 23.0, 0.18750117188232426, 0.14025966568541054, 0.03718895313408209], "isController": false}, {"data": ["01 - Send OTP", 10, 10, 100.0, 89.2, 32, 488, 42.5, 447.90000000000015, 488.0, 488.0, 0.18534994068801897, 0.14082251353054567, 0.04126932273131673], "isController": false}, {"data": ["08 - Search Content By Key", 10, 10, 100.0, 12.399999999999999, 9, 33, 10.5, 30.800000000000008, 33.0, 33.0, 0.18738873793685001, 0.14017555982385457, 0.040991286423685935], "isController": false}, {"data": ["04 - Public Latest Content", 10, 0, 0.0, 14.6, 11, 23, 13.0, 22.8, 23.0, 23.0, 0.18737469317393993, 0.26472164903783096, 0.041445671878806045], "isController": false}]}, function(index, item){
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
    createTable($("#errorsTable"), {"supportsControllersDiscrimination": false, "titles": ["Type of error", "Number of errors", "% in errors", "% in all samples"], "items": [{"data": ["500", 20, 20.0, 16.666666666666668], "isController": false}, {"data": ["401", 80, 80.0, 66.66666666666667], "isController": false}]}, function(index, item){
        switch(index){
            case 2:
            case 3:
                item = item.toFixed(2) + '%';
                break;
        }
        return item;
    }, [[1, 1]]);

        // Create top5 errors by sampler
    createTable($("#top5ErrorsBySamplerTable"), {"supportsControllersDiscrimination": false, "overall": {"data": ["Total", 120, 100, "401", 80, "500", 20, "", "", "", "", "", ""], "isController": false}, "titles": ["Sample", "#Samples", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors"], "items": [{"data": [], "isController": false}, {"data": ["11 - Continue Watching List", 10, 10, "401", 10, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["12 - Get Push Notifications", 10, 10, "401", 10, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["02 - Verify OTP", 10, 10, "500", 10, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["03 - Dashboard Filter Type3", 10, 10, "401", 10, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["09 - Request Signed Playback URL", 10, 10, "401", 10, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["10 - Get User Profile", 10, 10, "401", 10, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["06 - Movie Content Details", 10, 10, "401", 10, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["07 - Series Details", 10, 10, "401", 10, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["01 - Send OTP", 10, 10, "500", 10, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["08 - Search Content By Key", 10, 10, "401", 10, "", "", "", "", "", "", "", ""], "isController": false}, {"data": [], "isController": false}]}, function(index, item){
        return item;
    }, [[0, 0]], 0);

});
