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
    createTable($("#statisticsTable"), {"supportsControllersDiscrimination": true, "overall": {"data": ["Total", 1200, 1000, 83.33333333333333, 14.254999999999988, 7, 502, 10.0, 27.0, 37.0, 55.98000000000002, 3.8977363895917443, 3.7950433430316597, 0.8884066652510305], "isController": false}, "titles": ["Label", "#Samples", "FAIL", "Error %", "Average", "Min", "Max", "Median", "90th pct", "95th pct", "99th pct", "Transactions/s", "Received", "Sent"], "items": [{"data": ["02 - Public Latest Content", 100, 0, 0.0, 13.780000000000003, 9, 40, 12.0, 18.900000000000006, 23.94999999999999, 39.95999999999998, 0.33765190114902943, 0.43929369658768985, 0.07452082974578188], "isController": false}, {"data": ["01 - Search Content By Key", 100, 100, 100.0, 11.030000000000003, 7, 77, 9.0, 13.900000000000006, 15.899999999999977, 76.65999999999983, 0.3376678631364617, 0.2525913898071579, 0.0735350912885068], "isController": false}, {"data": ["01 - Get User Profile", 100, 100, 100.0, 10.719999999999997, 7, 34, 9.0, 15.0, 24.59999999999991, 33.989999999999995, 0.3376918089474822, 0.2526093023962611, 0.05870033397719905], "isController": false}, {"data": ["01 - Movie or Content Details", 100, 100, 100.0, 10.410000000000004, 8, 58, 9.0, 12.0, 13.0, 57.889999999999944, 0.33767242398149555, 0.2525948015330328, 0.07173890218474059], "isController": false}, {"data": ["02 - Series Details", 100, 100, 100.0, 9.949999999999998, 7, 34, 9.0, 12.0, 15.899999999999977, 33.82999999999991, 0.3376712837586866, 0.2525939485929237, 0.06679230324738474], "isController": false}, {"data": ["01 - Get User Push Notifications", 100, 100, 100.0, 10.169999999999993, 7, 27, 9.0, 13.0, 18.899999999999977, 26.97999999999999, 0.3376940896780425, 0.2526110084896294, 0.07057278827255965], "isController": false}, {"data": ["02 - Verify OTP", 100, 100, 100.0, 13.119999999999996, 9, 65, 11.0, 15.900000000000006, 21.94999999999999, 64.83999999999992, 0.3376074435689158, 0.25023832975469446, 0.10620787292118217], "isController": false}, {"data": ["01 - Request Signed Playback URL", 100, 100, 100.0, 10.590000000000002, 8, 41, 9.0, 14.0, 17.899999999999977, 40.81999999999991, 0.3376758446961255, 0.252597360387922, 0.12648004905585833], "isController": false}, {"data": ["03 - Public Top Ten Content", 100, 0, 0.0, 17.85, 14, 62, 16.0, 20.0, 34.0, 61.82999999999991, 0.3376576016855868, 0.9783497111339217, 0.06495951907427791], "isController": false}, {"data": ["02 - Continue Watching List", 100, 100, 100.0, 10.160000000000002, 7, 43, 9.0, 12.0, 14.899999999999977, 42.85999999999993, 0.33769294930891136, 0.25261015544006454, 0.0689236585991821], "isController": false}, {"data": ["01 - Send OTP", 100, 100, 100.0, 42.98999999999999, 26, 502, 36.0, 52.80000000000001, 63.849999999999966, 497.84999999999786, 0.33704986989875024, 0.25607890505979264, 0.0747171098310706], "isController": false}, {"data": ["01 - Dashboard Filter Type3", 100, 100, 100.0, 10.29, 8, 54, 9.0, 12.0, 14.899999999999977, 53.69999999999985, 0.33765532144786603, 0.2525820080361966, 0.06627804649513776], "isController": false}]}, function(index, item){
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
    createTable($("#errorsTable"), {"supportsControllersDiscrimination": false, "titles": ["Type of error", "Number of errors", "% in errors", "% in all samples"], "items": [{"data": ["500", 200, 20.0, 16.666666666666668], "isController": false}, {"data": ["401", 800, 80.0, 66.66666666666667], "isController": false}]}, function(index, item){
        switch(index){
            case 2:
            case 3:
                item = item.toFixed(2) + '%';
                break;
        }
        return item;
    }, [[1, 1]]);

        // Create top5 errors by sampler
    createTable($("#top5ErrorsBySamplerTable"), {"supportsControllersDiscrimination": false, "overall": {"data": ["Total", 1200, 1000, "401", 800, "500", 200, "", "", "", "", "", ""], "isController": false}, "titles": ["Sample", "#Samples", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors"], "items": [{"data": [], "isController": false}, {"data": ["01 - Search Content By Key", 100, 100, "401", 100, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["01 - Get User Profile", 100, 100, "401", 100, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["01 - Movie or Content Details", 100, 100, "401", 100, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["02 - Series Details", 100, 100, "401", 100, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["01 - Get User Push Notifications", 100, 100, "401", 100, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["02 - Verify OTP", 100, 100, "500", 100, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["01 - Request Signed Playback URL", 100, 100, "401", 100, "", "", "", "", "", "", "", ""], "isController": false}, {"data": [], "isController": false}, {"data": ["02 - Continue Watching List", 100, 100, "401", 100, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["01 - Send OTP", 100, 100, "500", 100, "", "", "", "", "", "", "", ""], "isController": false}, {"data": ["01 - Dashboard Filter Type3", 100, 100, "401", 100, "", "", "", "", "", "", "", ""], "isController": false}]}, function(index, item){
        return item;
    }, [[0, 0]], 0);

});
