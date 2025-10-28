// ตัวอย่าง Node.js/Express endpoint
app.post('/notification/fire-report', async (req, res) => {
  const { fireForestId, location, severity, areaType, timestamp } = req.body;
  
  // ดึงรายชื่อ agency ทั้งหมด
  const agencies = await getActiveAgencies();
  
  // ส่ง push notification ไปยัง agency แต่ละคน
  const notifications = agencies.map(agency => {
    return sendPushNotification(agency.fcmToken, {
      title: `🔥 แจ้งเหตุไฟป่าใหม่`,
      body: `พื้นที่: ${location} | ระดับ: ${severity}`,
      data: {
        fireForestId: fireForestId.toString(),
        type: 'fire_report',
        location,
        severity
      }
    });
  });
  
  await Promise.all(notifications);
  res.json({ success: true });
});