const ExcelJS = require('exceljs');
const path = require('path');

async function createExcelReport(testResults, filename = 'report_web.xlsx') {
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Test Results');

    worksheet.columns = [
        { header: 'Test ID', key: 'id', width: 10 },
        { header: 'Test Case Name', key: 'name', width: 40 },
        { header: 'Status', key: 'status', width: 15 },
        { header: 'Error/Details', key: 'details', width: 50 },
        { header: 'Timestamp', key: 'timestamp', width: 25 }
    ];

    testResults.forEach(result => {
        const row = worksheet.addRow(result);
        if (result.status === 'Pass') {
            row.getCell('status').fill = {
                type: 'pattern',
                pattern: 'solid',
                fgColor: { argb: 'FF90EE90' } // Light Green
            };
        } else {
            row.getCell('status').fill = {
                type: 'pattern',
                pattern: 'solid',
                fgColor: { argb: 'FFFFCCCB' } // Light Red
            };
        }
    });

    const filePath = path.join(__dirname, '..', filename);
    await workbook.xlsx.writeFile(filePath);
    console.log(`Report generated: ${filePath}`);
}

module.exports = { createExcelReport };
